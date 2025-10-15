import {
  GetSecretValueCommand,
  SecretsManagerClient,
} from "@aws-sdk/client-secrets-manager";

async function getSecretValue(secretName) {
  const client = new SecretsManagerClient();

  const response = await client.send(
    new GetSecretValueCommand({
      SecretId: secretName,
    })
  );

  return response.SecretString;
}

const sftpAnacUsername = await getSecretValue(process.env.SFTP_ANAC_USERNAME_SECRET_NAME)
const sftpAnacPassword = await getSecretValue(process.env.SFTP_ANAC_USER_PASSWORD_SECRET_NAME)

export const handler =  async function (event) {
  console.log(`Username: ${event.username}, ServerId: ${event.serverId}`)

  if (event.username !== sftpAnacUsername || event.password !== sftpAnacPassword) {
    console.log("Invalid credentials");
    return {}
  }

  const homeDirectory = [
    {
      Entry: "/",
      Target: `/${process.env.SFTP_ANAC_BUCKET_NAME}`
    }
  ]

  console.log("Access authorized");

  return {
    Role: process.env.SFTP_ANAC_BUCKET_ACCESS_ROLE_ARN,
    HomeDirectoryDetails: JSON.stringify(homeDirectory),
    HomeDirectoryType: "LOGICAL"
  };
}
