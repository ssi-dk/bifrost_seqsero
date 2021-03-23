from setuptools import setup, find_packages

setup(
    name='bifrost_seqsero',
    version='v0_0_1',
    description='Datahandling functions for bifrost (later to be API interface)',
    url='https://github.com/ssi-dk/bifrost_seqsero',
    author="Kristoffer Kiil",
    author_email="krki@ssi.dk",
    packages=find_packages(),
    install_requires=[
        'bifrostlib >= 2.1.9',
    ],
    package_data={"bifrost_seqsero": ['config.yaml']},
    include_package_data=True
)
