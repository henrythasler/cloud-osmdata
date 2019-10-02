[
    {
      "name": "${project}",
      "image": "${repository_url}:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 5432,
          "hostPort": 5432,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "POSTGRES_PASSWORD",
          "value": "${postgres_password}"
        }
      ]
    }
]