for combo in $(cat vendor/cm/crdroid-build-targets)
do
    add_lunch_combo $combo
done
