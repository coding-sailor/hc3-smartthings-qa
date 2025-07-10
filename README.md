# Fibaro SmartThings AC Controller

A Fibaro Home Center 3 QuickApp for controlling Samsung SmartThings compatible air conditioning units. This app provides seamless integration between your Fibaro smart home system and SmartThings AC devices.

## ⚠️ Disclaimer

This is an **unofficial, third-party implementation** and is not affiliated with, endorsed by, or supported by Samsung SmartThings or Fibaro. This project is developed independently by the community for educational and personal use.

## Features

- **Auto-Discovery**: Automatically discovers and adds SmartThings AC devices
- **Cooling Mode Control**: Thermostat functionality with cooling mode support (other modes are not supported)
- **Fan Control**: Multiple fan speed settings (Auto, Low, Medium, High, Turbo)
- **Optional Modes**: Support for WindFree and Speed modes
- **Automatic Status Updates**: Periodic polling and status updates (default: 60-second intervals)
- **OAuth2 Authentication**: Secure token-based authentication with auto-refresh

## Installation

1. **Download** the `SmartThings.fqa` file from this repository
2. **Import** the .fqa file into your Fibaro Home Center 3
3. **Configure** the QuickApp variables (see Configuration section)

## Configuration

### 1. SmartThings API Setup

#### Why OAuth2 is Required

SmartThings Personal Access Tokens (PATs) created after December 30, 2024 are only valid for 24 hours. For continuous access, SmartThings recommends using OAuth2 authorization code flow instead.

#### Step 1: Create SmartThings App (OAuth Client)

**Install SmartThings CLI:**

- **macOS**: `brew install smartthingscommunity/smartthings/smartthings`
- **Windows**: Download `smartthings.msi` from [GitHub releases](https://github.com/SmartThingsCommunity/smartthings-cli/releases)
- **Linux**: Download and extract the appropriate binary

**Create the app:**

```bash
smartthings apps:create
```

**Configuration:**

- **Scopes**: `r:devices:*`, `x:devices:*`
- **Redirect URI**: `https://my.local/callback`

**Save the OAuth credentials:**

```
OAuth Client Id: 3f8b4e2a-9c6d-4f7e-8a1b-5c3d9e7f2a8b
OAuth Client Secret: 7k9m2n4p-6q8r-1s3t-5u7v-9w1x3y5z7a9b
```

For more details see: [SmartThings API: Taming the OAuth 2.0 Beast](https://levelup.gitconnected.com/smartthings-api-taming-the-oauth-2-0-beast-5d735ecc6b24)

#### Step 2: Generate Refresh Token

**Install Node.js:**

- **Windows**: Download installer from [nodejs.org](https://nodejs.org/) and run the .msi file
- **macOS**: `brew install node` or download installer from [nodejs.org](https://nodejs.org/)
- **Linux**:
  - Ubuntu/Debian: `sudo apt install nodejs npm`
  - CentOS/RHEL: `sudo yum install nodejs npm`
  - Or download from [nodejs.org](https://nodejs.org/)

**Verify installation:**

```bash
node --version
```

**Run the token generator:**

```bash
node get-token.js
```

The script will:

1. **Ask for your OAuth Client ID and Client Secret** (from Step 1)
2. **Generate and display the authorization URL**
3. **Wait for authorization code** from the callback URL
4. **Exchange the code for tokens**
5. **Output all required QuickApp variables**

**Token Information:**

- **Access Token**: Valid for 24 hours
- **Refresh Token**: Valid for 30 days, can be renewed
- **Auto-refresh**: The QuickApp automatically refreshes tokens before expiry

### 2. QuickApp Variables

Set the following variables in your QuickApp:

| Variable       | Description                   | Required |
| -------------- | ----------------------------- | -------- |
| `clientId`     | SmartThings API Client ID     | Yes      |
| `clientSecret` | SmartThings API Client Secret | Yes      |
| `refreshToken` | OAuth2 Refresh Token          | Yes      |

### 3. Device Configuration (optional)

Each AC device can be configured with the following optional variables:

| Variable       | Description                       | Default |
| -------------- | --------------------------------- | ------- |
| `pollInterval` | Status polling interval (seconds) | 60      |

**SmartThings API Rate Limits:**

According to the [SmartThings API documentation](https://developer.smartthings.com/docs/getting-started/rate-limits#devices), device APIs have a rate limit of **12 requests per minute per device**. This applies to:

- Get device state requests
- Send device commands
- Create state events

**Recommended Polling Intervals:**

- **Minimum recommended**: 10 seconds (6 polling requests/minute)
- **Default setting**: 60 seconds (1 polling request/minute, optimal for most use cases)

## Usage

### Thermostat Control

- **Off**: Turns off the AC unit
- **Cool**: Activates cooling mode with auto fan

### Fan Control

- **Auto**: Automatic fan speed
- **Low/Medium/High/Turbo**: Manual fan speed control

### Optional Modes

- **WindFree**: Samsung's wind-free cooling technology
- **Speed**: High-speed cooling mode

### Temperature Control

- Use the standard Fibaro thermostat interface
- Set cooling setpoint between 16°C - 30°C
- 1°C increments supported

## Contributing

1. Fork the repository
2. Create your feature branch
3. Test thoroughly with real devices
4. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

This project is provided as-is for educational and personal use.
