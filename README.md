# ft_server

## Commands

```bash
# Restart docker
docker-machine restart
eval $(docker-machine env default)

# Build image
docker image build -t test .

# Clear
docker system prune
docker system prune -a
docker image prune
docker image prune -a

# Run container
docker run -tid --rm --privileged --name test -p 443:443 -p 80:80 -p 8080:8080 test

# Stop container
docker container stop test

# Running containers
docker ps
```
