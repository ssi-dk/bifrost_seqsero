# bifrost_seqsero

This component is run given a sample id already added into the bifrostDB. If the sample is registered as Salmonella enterica, this will pull the paired_reads and predicts the serotype using Seqsero v1. The output of this is a serotype string and the serotype name according to the Kauffman-White scheme.

## Howto launch
  /bifrost/components/bifrost_seqsero$ docker-compose run bifrost_seqsero
## How to debug
  /bifrost/components/bifrost_seqsero$ docker-compose run --entrypoint=bash bifrost_seqsero