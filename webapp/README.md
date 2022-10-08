# Steps

- add your account to whiteListAddressed

```
docker build -t aws-token . --no-cache
docker run -p 3000:3000 aws-token
```
