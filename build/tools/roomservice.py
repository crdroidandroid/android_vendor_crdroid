#!/usr/bin/env python3
# Copyright (C) 2023-2026 crDroid Android Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


import base64
import json
import netrc
import os
import socket
import ssl
import sys
import time

from xml.etree import ElementTree

import urllib.request
import urllib.error
import urllib.parse

DEBUG = False

custom_local_manifest = ".repo/local_manifests/roomservice.xml"
custom_default_revision =  "16.0"
custom_dependencies = "crdroid.dependencies"
org_manifest = "crdroidandroid"  # leave empty if org is provided in manifest
org_display = "crDroid Android"  # needed for displaying

github_auth = None

local_manifests = '.repo/local_manifests'
if not os.path.exists(local_manifests):
    os.makedirs(local_manifests)


def debug(*args, **kwargs):
    if DEBUG:
        print(*args, **kwargs)


def add_auth(g_req):
    global github_auth
    if github_auth is None:
        try:
            auth = netrc.netrc().authenticators("api.github.com")
        except (netrc.NetrcParseError, IOError):
            auth = None
        if auth:
            github_auth = base64.b64encode(
                ('%s:%s' % (auth[0], auth[2])).encode()
            ).decode()
        else:
            github_auth = ""
    if github_auth:
        g_req.add_header("Authorization", "Basic %s" % github_auth)


def indent(elem, level=0):
    # in-place prettyprint formatter
    i = "\n" + "  " * level
    if len(elem):
        if not elem.text or not elem.text.strip():
            elem.text = i + "  "
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
        for elem in elem:
            indent(elem, level+1)
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
    else:
        if level and (not elem.tail or not elem.tail.strip()):
            elem.tail = i

def load_manifest(manifest):
    try:
        man = ElementTree.parse(manifest).getroot()
    except (IOError, ElementTree.ParseError):
        man = ElementTree.Element("manifest")
    return man

def get_from_manifest(device_name):
    if os.path.exists(custom_local_manifest):
        man = load_manifest(custom_local_manifest)
        for local_path in man.findall("project"):
            lp = local_path.get("path").strip('/')
            if lp.startswith("device/") and lp.endswith("/" + device_name):
                return lp
    return None


def is_in_manifest(project_path):
    man = load_manifest(custom_local_manifest)
    for local_path in man.findall("project"):
        if local_path.get("path") == project_path:
            return True
    return False


def add_to_manifest(repos, fallback_branch=None):
    lm = load_manifest(custom_local_manifest)

    for repo in repos:
        repo_name = repo['repository']
        repo_path = repo['target_path']
        if 'branch' in repo:
            repo_branch=repo['branch']
        else:
            repo_branch=custom_default_revision
        if 'remote' in repo:
            repo_remote=repo['remote']
        elif "/" not in repo_name:
            repo_remote=org_manifest
        elif "/" in repo_name:
            repo_remote="crdroid"

        if is_in_manifest(repo_path):
            print('already exists: %s' % repo_path)
            continue

        print('Adding dependency:\nRepository: %s\nBranch: %s\nRemote: %s\nPath: %s\n' % (repo_name, repo_branch,repo_remote, repo_path))

        project = ElementTree.Element(
            "project",
            attrib={"path": repo_path,
                    "remote": repo_remote,
                    "name": "%s" % repo_name}
        )

        if repo_branch is not None:
            project.set('revision', repo_branch)
        elif fallback_branch:
            print("Using branch %s for %s" %
                  (fallback_branch, repo_name))
            project.set('revision', fallback_branch)
        else:
            print("Using default branch for %s" % repo_name)
        lm.append(project)

    indent(lm)
    raw_xml = "\n".join(('<?xml version="1.0" encoding="UTF-8"?>',
                         ElementTree.tostring(lm).decode()))

    f = open(custom_local_manifest, 'w')
    f.write(raw_xml)
    f.close()

_fetch_dep_cache = []


def validate_repository(repo_name, target_path):
    repo_lower = repo_name.lower()
    target_lower = target_path.lower()

    if not any(x in repo_lower for x in ('crdroidandroid', 'themuppets', 'lineageos')):
        return False, "Unsupported repository org"

    if 'lineageos' in repo_lower:
        if 'kernels' in repo_lower:
            return True, None
        if ('hardware' not in target_lower) and ('sepolicy' not in target_lower):
            return False, "LineageOS repositories allowed only with 'hardware' or 'sepolicy' repos"

    return True, None

def fetch_dependencies(repo_path, fallback_branch=None):
    global _fetch_dep_cache
    if repo_path in _fetch_dep_cache:
        return
    _fetch_dep_cache.append(repo_path)

    print('Looking for dependencies')
    print()

    dep_p = '/'.join((repo_path, custom_dependencies))
    if os.path.exists(dep_p):
        try:
            with open(dep_p) as dep_f:
                raw = dep_f.read()
                dependencies = json.loads(raw)
        except Exception as e:
            print("Error: Invalid dependencies formatting in %s" % (dep_p))
            print()
            sys.exit(1)
    else:
        dependencies = []
        print('%s has no additional dependencies.' % repo_path)

    fetch_list = []
    syncable_repos = []
    invalid_dependency = False

    for dependency in dependencies:
        repo = dependency.get('repository')
        target = dependency.get('target_path')
        if not repo or not target:
            print("Skipping dependency with missing 'repository' or 'target_path': %r" % dependency)
            continue

        ok, reason = validate_repository(repo, target)
        if not ok:
            print("Error for dependency '%s' => '%s': %s" % (repo, target, reason))
            invalid_dependency = True
            continue

        if not is_in_manifest(target):
            if not dependency.get('branch'):
                dependency['branch'] = custom_default_revision
            fetch_list.append(dependency)
            syncable_repos.append(target)
        else:
            print("Dependency already present in manifest: %s => %s" % (repo, target))

    if invalid_dependency:
        print("Aborting: one or more dependencies are not valid; not syncing repositories.")
        print()
        sys.exit(1)

    if fetch_list:
        print()
        print('Adding dependencies to manifest\n')
        add_to_manifest(fetch_list, fallback_branch)

    if syncable_repos:
        print('Syncing dependencies')
        os.system('repo sync --force-sync --no-tags --current-branch --no-clone-bundle -j2 %s' % ' '.join(syncable_repos))

    for deprepo in syncable_repos:
        fetch_dependencies(deprepo)


def has_branch(branches, revision):
    return revision in (branch['name'] for branch in branches)


def detect_revision(repo):
    """
    returns None if using the default revision, else return
    the branch name if using a different revision
    """
    print("Checking branch info")
    githubreq = urllib.request.Request(
        repo['branches_url'].replace('{/branch}', ''))
    try:
        with github_urlopen(githubreq, timeout=15) as resp:
            result = json.loads(resp.read().decode())
    except Exception as e:
        print("Failed to retrieve branch information from GitHub: %s" % e)
        sys.exit(1)

    print("Calculated revision: %s" % custom_default_revision)

    if has_branch(result, custom_default_revision):
        return custom_default_revision

    print("Branch %s not found" % custom_default_revision)
    sys.exit()


def github_urlopen(g_req, timeout=15, retries=3, backoff=2):
    add_auth(g_req)
    try:
        g_req.add_header("User-Agent", "%s roomservice/1.0" % org_display)
    except Exception:
        pass
    g_req.add_header("Accept", "application/vnd.github.v3+json")

    attempt = 0
    while True:
        try:
            debug("Opening URL:", g_req.full_url, "attempt", attempt+1)
            return urllib.request.urlopen(g_req, timeout=timeout)
        except (urllib.error.URLError, socket.timeout, TimeoutError, ssl.SSLError) as e:
            attempt += 1
            if attempt > retries:
                print("Error: failed to contact GitHub after %d attempts: %s" % (attempt, e))
                raise
            wait = backoff ** attempt
            print("Network error contacting GitHub (attempt %d/%d): %s. Retrying in %ds..." % (attempt, retries, e, wait))
            time.sleep(wait)


def main():
    global DEBUG
    try:
        depsonly = bool(sys.argv[2] in ['true', 1])
    except IndexError:
        depsonly = False

    if os.getenv('ROOMSERVICE_DEBUG'):
        DEBUG = True

    product = sys.argv[1]
    device = product[product.find("_") + 1:] or product

    if depsonly:
        repo_path = get_from_manifest(device)
        if repo_path:
            fetch_dependencies(repo_path)
        else:
            print("Trying dependencies-only mode on a "
                  "non-existing device tree?")
        sys.exit()

    print("Device {0} not found. Attempting to retrieve device repository from "
          "{1} Github (http://github.com/{2}).".format(device, org_display, org_manifest))

    githubreq = urllib.request.Request(
        "https://api.github.com/search/repositories?"
        "q={0}+user:{1}+in:name+fork:true".format(device, org_manifest))
    try:
        with github_urlopen(githubreq, timeout=15) as resp:
            result = json.loads(resp.read().decode())
    except urllib.error.URLError:
        print("Failed to search GitHub (network error)")
        sys.exit(1)
    except ValueError:
        print("Failed to parse return data from GitHub")
        sys.exit(1)
    except Exception as e:
        print("Unexpected error querying GitHub: %s" % e)
        sys.exit(1)

    repositories = []

    for res in result.get('items', []):
        repositories.append(res)

    for repository in repositories:
        repo_name = repository['name']

        if not (repo_name.startswith("android_device_") and
                repo_name.endswith("_" + device)):
            continue
        print("Found repository: %s" % repository['name'])

        fallback_branch = detect_revision(repository)
        manufacturer = repo_name.replace("android_device_", "").replace("_" + device, "")
        repo_path = "device/%s/%s" % (manufacturer, device)
        adding = [{'repository': "crdroidandroid/" + repo_name, 'target_path': repo_path}]

        add_to_manifest(adding, fallback_branch)

        print("Syncing repository to retrieve project.")
        os.system('repo sync --force-sync --no-tags --current-branch --no-clone-bundle -j2 %s' % repo_path)
        print("Repository synced!")

        fetch_dependencies(repo_path, fallback_branch)
        print("Done")
        sys.exit()

    print("Repository for %s not found in the %s Github repository list."
          % (device, org_display))
    print("If this is in error, you may need to manually add it to your "
          "%s" % custom_local_manifest)

if __name__ == "__main__":
    main()
