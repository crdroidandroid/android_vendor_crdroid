for combo in $(cat vendor/crdroid/crdroid-build-targets)
do
    add_lunch_combo $combo
done
