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
import glob
import json
import netrc
import os
import socket
import ssl
import subprocess
import sys
import time

from xml.etree import ElementTree

import urllib.request
import urllib.error
import urllib.parse

DEBUG = False

dryrun = os.getenv('ROOMSERVICE_DRYRUN') == 'true'
if dryrun:
    print('Dry run roomservice, no change will be made.')

custom_local_manifest = ".repo/local_manifests/roomservice.xml"
custom_default_revision = "16.0"
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


def get_manifest_path():
    """Find the current manifest path.
    In old versions of repo this is at .repo/manifest.xml.
    In new versions, .repo/manifest.xml includes an include
    to some arbitrary file in .repo/manifests."""
    m = ElementTree.parse('.repo/manifest.xml')
    try:
        m.findall('default')[0]
        return '.repo/manifest.xml'
    except IndexError:
        return '.repo/manifests/%s' % m.find('include').get('name')


def get_from_manifest(device_name):
    # Look across all local manifest snippets, not just roomservice.xml
    for path in glob.glob('.repo/local_manifests/*.xml'):
        try:
            man = ElementTree.parse(path).getroot()
        except (IOError, ElementTree.ParseError):
            continue
        for local_path in man.findall('project'):
            lp = (local_path.get('path') or '').strip('/')
            if lp.startswith('device/') and lp.endswith('/' + device_name):
                return lp
    return None


def is_in_manifest(project_path):
    # Search across all files inside .repo/local_manifests/
    for path in glob.glob('.repo/local_manifests/*.xml'):
        try:
            lm = ElementTree.parse(path).getroot()
        except (IOError, ElementTree.ParseError):
            continue
        for local_path in lm.findall('project'):
            if local_path.get('path') == project_path:
                return True

    # Also search in the main manifest so we don't shadow upstream entries
    try:
        lm = ElementTree.parse(get_manifest_path()).getroot()
    except (IOError, ElementTree.ParseError):
        lm = ElementTree.Element('manifest')
    for local_path in lm.findall('project'):
        if local_path.get('path') == project_path:
            return True

    return False


def add_to_manifest(repos, fallback_branch=None):
    if dryrun:
        for repo in repos:
            print('[Dry run] Would add: %s -> %s' % (repo['repository'], repo['target_path']))
        return

    lm = load_manifest(custom_local_manifest)

    for repo in repos:
        repo_name = repo['repository']
        repo_path = repo['target_path']
        if 'branch' in repo and repo['branch']:
            repo_branch = repo['branch']
        elif fallback_branch:
            repo_branch = fallback_branch
        else:
            repo_branch = custom_default_revision

        if 'remote' in repo:
            repo_remote = repo['remote']
        elif "/" not in repo_name:
            repo_remote = org_manifest
        else:  # "/" in repo_name
            repo_remote = "crdroid"

        if is_in_manifest(repo_path):
            print('already exists: %s' % repo_path)
            continue

        print('Adding dependency:\nRepository: %s\nBranch: %s\nRemote: %s\nPath: %s\n'
              % (repo_name, repo_branch, repo_remote, repo_path))

        project = ElementTree.Element(
            "project",
            attrib={
                "path": repo_path,
                "remote": repo_remote,
                "name": "%s" % repo_name,
                "revision": repo_branch,
            }
        )
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

    print('Looking for dependencies in %s' % repo_path)
    print()

    dep_p = '/'.join((repo_path, custom_dependencies))
    if os.path.exists(dep_p):
        try:
            with open(dep_p) as dep_f:
                dependencies = json.loads(dep_f.read())
        except Exception:
            print("Error: Invalid dependencies formatting in %s" % dep_p)
            print()
            sys.exit(1)
    else:
        dependencies = []
        print('%s has no additional dependencies.' % repo_path)

    fetch_list = []
    syncable_repos = []
    verify_repos = []
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
                dependency['branch'] = fallback_branch or custom_default_revision
            fetch_list.append(dependency)
            if target not in syncable_repos:
                syncable_repos.append(target)
        else:
            print("Dependency already present in manifest: %s => %s" % (repo, target))

        verify_repos.append(target)

        # If the manifest already references it but it isn't actually on disk
        # (e.g. partial sync), make sure we sync it
        if not os.path.isdir(target) and target not in syncable_repos:
            syncable_repos.append(target)

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
        if not dryrun:
            subprocess.run(
                ['repo', 'sync', '--force-sync', '--no-tags',
                 '--current-branch', '--no-clone-bundle', '-j2']
                + syncable_repos
            )

    # Recurse over ALL deps (not just newly added) so nested deps on
    # already-present repos still get fetched. _fetch_dep_cache guards loops.
    for deprepo in verify_repos:
        fetch_dependencies(deprepo, fallback_branch)


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
            print("Network error contacting GitHub (attempt %d/%d): %s. Retrying in %ds..."
                  % (attempt, retries, e, wait))
            time.sleep(wait)


def git_ls_remote_branches(repo_name):
    """Get list of branch names for a GitHub repository via git ls-remote.
    Avoids the GitHub Search/Branches API rate limits and works
    without authentication."""
    if '/' in repo_name:
        url = 'https://:@github.com/%s' % repo_name
    else:
        url = 'https://:@github.com/%s/%s' % (org_manifest, repo_name)

    try:
        proc = subprocess.run(
            ['git', 'ls-remote', '-h', url],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=30,
        )
        stdout = proc.stdout.decode(errors='replace')
        branches = [line.split('refs/heads/')[-1]
                    for line in stdout.splitlines() if 'refs/heads/' in line]
        return branches
    except Exception as e:
        debug("git ls-remote failed for %s: %s" % (repo_name, e))
        return []


def get_default_or_fallback_revision(repo_name):
    """Prefer custom_default_revision (e.g. 16.0); otherwise try the
    space-separated branches in ROOMSERVICE_BRANCHES env var.
    Returns '' if nothing matches."""
    print("Checking branch info for %s" % repo_name)
    branches = git_ls_remote_branches(repo_name)

    if not branches:
        print("Failed to retrieve branch info for %s" % repo_name)
        return ''

    if custom_default_revision in branches:
        print("Calculated revision: %s" % custom_default_revision)
        return custom_default_revision

    if os.getenv('ROOMSERVICE_BRANCHES'):
        fallbacks = list(filter(bool, os.getenv('ROOMSERVICE_BRANCHES').split(' ')))
        for fallback in fallbacks:
            if fallback in branches:
                print("Using fallback branch: %s" % fallback)
                return fallback

    print("Default revision %s not found in %s. Bailing." % (custom_default_revision, repo_name))
    print("Branches found:")
    for branch in branches:
        print(branch)
    print("Use the ROOMSERVICE_BRANCHES environment variable to specify a list of fallback branches.")
    return ''


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

    for repository in result.get('items', []):
        repo_name = repository['name']

        if not (repo_name.startswith("android_device_") and
                repo_name.endswith("_" + device)):
            continue
        print("Found repository: %s" % repo_name)

        revision = get_default_or_fallback_revision('%s/%s' % (org_manifest, repo_name))
        if revision == '':
            # Some devices share a codename across older releases; keep
            # scanning other matches before giving up.
            continue

        manufacturer = repo_name.replace("android_device_", "").replace("_" + device, "")
        repo_path = "device/%s/%s" % (manufacturer, device)

        device_repository = {
            'repository': '%s/%s' % (org_manifest, repo_name),
            'target_path': repo_path,
            'branch': revision,
        }

        add_to_manifest([device_repository])

        if not dryrun:
            print("Syncing repository to retrieve project.")
            subprocess.run([
                'repo', 'sync', '--force-sync', '--no-tags', '--current-branch',
                '--no-clone-bundle', '-j2', repo_path
            ])
            print("Repository synced!")

        fetch_dependencies(repo_path, revision)
        print("Done")
        sys.exit()

    print("Repository for %s not found in the %s Github repository list."
          % (device, org_display))
    print("If this is in error, you may need to manually add it to your "
          "%s" % custom_local_manifest)


if __name__ == "__main__":
    main()
