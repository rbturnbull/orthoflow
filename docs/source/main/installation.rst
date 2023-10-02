============
Installation
============

Orthoflow can be installed using conda, PyPI or from source.

Conda Installation
==================

Information coming soon.

pip Installation
==================

Orthoflow can be installed with pip from the Python Package Index (PyPI) as follows.

.. code-block::

    pip install orthoflow

Orthoflow can also be installed directly from Github using pip as follows.

.. code-block::

    pip install git+https://github.com/rbturnbull/orthoflow.git


.. note::

    If installing with pip, conda needs to be available on the system for the workflow to run.

Source Installation
===================

To install from the source code, first ensure that the dependency manager `poetry <https://python-poetry.org/>`_ is installed on the system. You can `install the latest version of poetry <https://python-poetry.org/docs/master/#installing-with-the-official-installer>`_ on Mac and Linux like this:

.. code-block:: bash

    curl -sSL https://install.python-poetry.org | python3 -

On windows, it can be installed with this command:

.. code-block:: bash

    (Invoke-WebRequest -Uri https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py -UseBasicParsing).Content | python -

Then clone the orthoflow repository from github:

.. code-block:: bash

    git clone https://github.com/rbturnbull/orthoflow.git
    cd orthoflow

Install the code into a virtual environment managed by poetry as follows:

.. code-block:: bash

    poetry install

Enter into the virtual environment as follows:

.. code-block:: bash

    poetry shell

.. note::

    If installing from source, conda needs to be available on the system for the workflow to run.


Recommendations for Mac M1 and Windows systems
==============================================

Information coming soon.



Setting up on HPC system
========================

Information coming soon.
