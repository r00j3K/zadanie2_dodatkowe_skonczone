docker run -d --rm --name buildkitd --privileged moby/buildkit:latest - uruchomienie kontenera z demonem builtkitd
export BUILDKIT_HOST=docker-container://buildkitd - ustawienie zmiennej środowiskowej, która podczas budowania obrazu przy użyciu programu buildctl, gdzie znajduje się niezbędny demon buildkitd
buildctl build --frontend=dockerfile.v0 --ssh default=$SSH_AUTH_SOCK --local context=. --local dockerfile=. --opt build-arg:VERSION=1.0.0 --output type=image,name=ghcr.io/r00j3K/pawcho:lab6,push=true
docker run -d --rm -p 80:80 --name app ghcr.io/r00j3k/pawcho:lab6
