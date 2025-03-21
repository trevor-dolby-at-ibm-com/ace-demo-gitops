# QM with pre-defind PV for data

This directory contains files that create a QM with persistent volumes on an NFS host without using a storageClass.

## Commands


Create a storage class that will never provision anything:
```
oc apply -f no-provisioner-sc.yaml
```
This is needed to ensure that volumes are not accidentally created in the wrong storage class, as the resilience
characteristics would not be sufficient for DR.

Once that SC exists, run the following:
```
oc apply -f testqm-pv.yaml
oc apply -f testqm-pvc.yaml
oc apply -f testqm.yaml
```

It is also possible to set
```
storageClassName: ""
```
in the PV and PVC definitions and thereby avoid the need for creating the no-provisioner-sc. However, if the
MQ QM is created first (before the PVC) then it will provision storage using the default storage class for
the cluster (if any). This may not be desirable.

