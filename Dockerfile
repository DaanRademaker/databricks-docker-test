FROM ubuntu:22.04
ENV DATABRICKS_RUNTIME_VERSION=13.3

ARG POETRY_VERSION=1.2.2
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    # first we install some required packages on the Ubuntu base image
    && apt-get -y upgrade \
    && apt-get install --yes \
    openjdk-8-jdk \
    iproute2 \
    bash \
    sudo \
    coreutils \
    procps \
    curl \
    fuse \
    gcc \
    software-properties-common \
    python3.10 \
    python3.10-dev \
    python3.10-distutils \
    && /var/lib/dpkg/info/ca-certificates-java.postinst configure \
    # install pip so we can install some python packages
    && curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
    && /usr/bin/python3.10 get-pip.py pip==22.2.2 setuptools==63.4.1 wheel==0.37.1 \
    && rm get-pip.py \
    # install poetry
    && curl -fLSs https://install.python-poetry.org -o $HOME/get-poetry.py \
    && python3.10 $HOME/get-poetry.py --yes \
    # set poetry in path
    && export PATH="$HOME/.local/bin:$PATH" \
    # workaround for PEP440 bug https://bugs.launchpad.net/ubuntu/+source/python-debian/+bug/1926870
    && pip uninstall -y distro-info \
    && poetry config virtualenvs.create false \
    # get virtualenv
    && /usr/local/bin/pip3.10 install --no-cache-dir virtualenv==20.24.2 \
    # create a virtualenv for python3.10 note the /databricks/python3 file path this is where Databricks looks for the virtualenv
    && virtualenv --python=python3.10 --system-site-packages /databricks/python3 --no-download  --no-setuptools \
    ## install some default packages needed, that are required by the cluster.
    && /databricks/python3/bin/pip install \
    six==1.16.0 \
    jedi==0.18.1 \
    # ensure minimum ipython version for Python autocomplete with jedi 0.17.x
    ipython==8.10.0 \
    numpy==1.21.5 \
    pandas==1.4.4 \
    pyarrow==8.0.0 \
    matplotlib==3.5.2 \
    jinja2==2.11.3 \
    ipykernel==6.17.1 \
    databricks-connect==13.2.0 \
    black==22.6.0 \
    tokenize-rt==4.2.1 \
    && apt-get purge --auto-remove --yes \
    python3-virtualenv \
    virtualenv \
    file \
    gnupg2  \
    libtool \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY pyproject.toml poetry.lock /app/
COPY docker_test docker_test

RUN export PATH="$HOME/.local/bin:$PATH" \
    && poetry install --only main \
    # cleanup image
    && apt-get remove -y gcc  \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

ENV USER root

# this is where databricks runtime looks for the python binary! You can experiment
# and change it to your own path as long as you setup a proper virtualenv with the packages above
ENV PYSPARK_PYTHON=/databricks/python3/bin/python3
