# Steps

- Update the ERC721 contract address
- Run the web server with docker

```
docker build -t aws-token . --no-cache
docker run -p 3000:3000 aws-token
```
