# Unit Tests with RSpec

Classic RSpec tests are located under `/spec/kitchen` directory.

# Integration Tests with Docker and Travis

Integration tests can be found under `/spec/integration`.

They consist of
* `.kitchen.yml` for testing configuration
* `modules/` and `manifests/` as puppet code under test
* `test/integration/<suite>/serverspec` serverspec tests for verification step
