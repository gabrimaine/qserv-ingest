########################
Set up ingest input data
########################

This `example for input data <https://github.com/lsst-dm/qserv-ingest/tree/tickets/DM-24587/data/example_db>`__ is used by Qserv ingest continuous integration process.

Some metadata file are required:

- `metadata.json`: contains the name of the files describing the database, the tables, the indexes, and also the path to the chunk files.
- `<database_name>.json`: describe the database to register inside the replication service and where the data will be ingested, its format is described here: https://confluence.lsstcorp.org/pages/viewpage.action?pageId=133333850#UserguidefortheQservIngestsystem(APIversion1)-RegisteringanewdatabaseinQserv
- `<table_name>.json`: each file describes a table to register inside the replication service and where the data will be ingested, its format is described here: https://confluence.lsstcorp.org/pages/viewpage.action?pageId=133333850#UserguidefortheQservIngestsystem(APIversion1)-Registeringatable

Prerequisites
=============

For all setups
--------------

-  Access to a Kubernetes v1.14.2+ cluster via a valid ``KUBECONFIG`` file.
-  Dynamic volume provisionning need to be available on the Kubernetes cluster (for example `kind <https://kind.sigs.k8s.io/>`__ for or
   GKE).

For a development workstation
-----------------------------

-  Ubuntu LTS is recommended
-  8 cores, 16 GB RAM, 30GB for the partition hosting docker entities
   (images, volumes, containers, etc). Use ``df`` command as below to
   find its size.

   .. code:: bash

       sudo df –sh /var/lib/docker # or /var/snap/docker/common/var-lib-docker/

-  Internet access without proxy
-  ``sudo`` access
-  Install dependencies below:

   .. code:: bash

       sudo apt-get install curl docker.io git vim

-  Add current user to docker group and restart gnome session

   .. code:: bash

       sudo usermod -a -G docker <USER>

-  Install Kubernetes locally using this `simple k8s install script <https://github.com/k8s-school/kind-travis-ci>`__, based on
   `kind <https://kind.sigs.k8s.io/>`__.


Deploy qserv-operator
=====================

.. code:: sh

    # Deploy qserv-operator in current namespace
    curl -fsSL https://raw.githubusercontent.com/lsst/qserv-operator/master/deploy/qserv.sh | bash -s --install-kubedb

The ``--install-kubedb`` option enable ``qserv-operator`` to set-up a
Redis cluster for managing its secondary index (OnjectID,ChunkId). It
can be skipped for a regular Qserv installation.

Deploy a qserv instance
=======================

Deployments below are recommended for development purpose, or continuous
integration. Qserv install customization is handled with
`Kustomize <https://github.com/kubernetes-sigs/kustomize>`__, which is a
template engine allowing to customize kubernetes Yaml files.
``Kustomize`` is integrated with ``kubectl`` (``-k`` option).

with default settings
---------------------

.. code:: sh

    # Install a qserv instance with default settings inside default namespace
    kubectl apply -k https://github.com/lsst/qserv-operator/overlays/dev --namespace='default'

with a Redis cluster
--------------------

.. code:: sh

    # Install a qserv instance plus a Redis cluster inside default namespace
    # This overlay is used on Travis-CI, o, top of kind
    kubectl apply -k https://github.com/lsst/qserv-operator/ci-redis --namespace='default'

Undeploy a qserv instance
=========================

First list all Qserv instances running in a given namespace

.. code:: sh

    kubectl get qserv -n "<namespace>"

It will output something like:

::

    NAME            AGE
    qserv   59m

Then delete this Qserv instance

.. code:: sh

    kubectl delete qserv qserv -n "<namespace>"

To delete all Qserv instances inside a namespace:

.. code:: sh

    kubectl delete qserv --all -n "<namespace>"

All qserv storage will remain untouch by this operation.

Deploy a qserv instance with custom settings
============================================

Example are available, see below:

.. code:: sh

    # Install a qserv instance with custom settings
    kubectl apply -k https://github.com/lsst/qserv-operator/overlays/ncsa_dev --namespace='qserv-prod'

In order to create a customized Qserv instance, create a ``Kustomize``
overlay using instructions below:

.. code:: sh

    git clone https://github.com/lsst/qserv-operator.git
    cd qserv-operator
    cp -r overlays/dev/ overlays/<customized-overlay>

Then add custom setting, for example container image versions, by
editing ``overlays/<customized-overlay>/qserv.yaml``:

::

    apiVersion: qserv.lsst.org/v1alpha1
    kind: Qserv
    metadata:
      name: qserv
    spec:
      storageclass: "standard"
      storagecapacity: "1Gi"
      # Used by czar and worker pods
      worker:
        replicas: 3
        image: "qserv/qserv:ad8405c"
      replication:
          image: "qserv/replica:tools-w.2018.16-1171-gcbabd53"
          dbimage: "mariadb:10.2.16"
      xrootd:
        image: "qserv/qserv:ad8405c"

It is possible to use any recent Qserv image generated by `Qserv
Travis-CI <https://travis-ci.org/lsst/qserv/>`__

And finally create customized Qserv instance:

.. code:: sh

    kubectl apply -k overlays/my-qserv/ --namespace='<namespace>'

Launch integration tests
========================

.. code:: sh

    ./run-integration-tests.sh
