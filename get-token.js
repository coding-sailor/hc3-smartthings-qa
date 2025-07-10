const readline = require('readline');

const baseUrl = "https://api.smartthings.com";
const redirect_uri = "https://my.local/callback";

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function prompt(question) {
  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      resolve(answer.trim());
    });
  });
}

function getAuthorizationUrl(client_id) {
  const params = new URLSearchParams({
    client_id,
    redirect_uri,
    response_type: "code",
    scope: "r:devices:* x:devices:*",
  });

  return `${baseUrl}/oauth/authorize?${params.toString()}`;
}

async function exchangeCodeForTokens(client_id, client_secret, code) {
  const credentials = Buffer.from(`${client_id}:${client_secret}`).toString(
    "base64"
  );

  const response = await fetch(`${baseUrl}/oauth/token`, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      Accept: "application/json",
      Authorization: `Basic ${credentials}`,
    },
    body: new URLSearchParams({
      grant_type: "authorization_code",
      client_id,
      client_secret,
      redirect_uri,
      code,
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(
      `Failed to exchange code for tokens. Code: ${response.status} Body: ${error}`
    );
  }

  const data = await response.json();
  return data;
}

async function main() {
  try {
    console.log("🔧 SmartThings Token Generator for Fibaro QuickApp");
    console.log("=" .repeat(50));
    console.log();

    // Get client credentials
    console.log("📋 Step 1: Enter your SmartThings API credentials");
    console.log();
    
    const client_id = await prompt("Enter your Client ID: ");
    if (!client_id) {
      console.log("❌ Client ID is required!");
      process.exit(1);
    }

    const client_secret = await prompt("Enter your Client Secret: ");
    if (!client_secret) {
      console.log("❌ Client Secret is required!");
      process.exit(1);
    }

    console.log();
    console.log("=" .repeat(50));
    
    // Generate and display authorization URL
    console.log("🔗 Step 2: Authorization URL");
    console.log();
    const authUrl = getAuthorizationUrl(client_id);
    console.log("Copy and paste this URL into your browser:");
    console.log();
    console.log(authUrl);
    console.log();
    console.log("📌 After authorization, you'll be redirected to a callback URL.");
    console.log("   Copy the 'code' parameter from the callback URL.");
    console.log(`   Example: ${redirect_uri}?code=ABC123`);
    console.log("   The code would be: ABC123");
    console.log();
    
    // Get authorization code
    const code = await prompt("Enter the authorization code: ");
    if (!code) {
      console.log("❌ Authorization code is required!");
      process.exit(1);
    }

    console.log();
    console.log("🔄 Exchanging code for tokens...");
    console.log();

    // Exchange code for tokens
    const tokens = await exchangeCodeForTokens(client_id, client_secret, code);
    
    // Display results
    console.log("✅ Success! Token generated successfully.");
    console.log("=" .repeat(50));
    console.log();
    console.log("📋 Fibaro QuickApp Variables:");
    console.log("   Copy these values to your QuickApp variables:");
    console.log();
    console.log(`clientId: ${client_id}`);
    console.log(`clientSecret: ${client_secret}`);
    console.log(`refreshToken: ${tokens.refresh_token}`);
    console.log();
    console.log("🎉 Setup complete! Use the variables above in your Fibaro QuickApp.");
    
  } catch (error) {
    console.error("❌ Error:", error.message);
    process.exit(1);
  } finally {
    rl.close();
  }
}

main();
