from setuptools import setup, find_packages

setup(
    name='bifrost_seqsero',
    version='1.1.1',
    description='SeqSero component for salmonella serotyping',
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
