# JiraManager

A Ruby command-line tool to efficiently manage and analyze your Jira tickets.

## 📋 Description

JiraManager is a simple and efficient Ruby utility that allows you to interact with the Jira API to retrieve assigned tickets. It provides a colorful and intuitive command-line interface to quickly visualize your tickets or those assigned to a specific email.

## ✨ Features

- 🎯 **Assigned ticket retrieval**: Display your Jira tickets with their status
- 📧 **Email-based tickets**: Display tickets assigned to a specific email
- 📧 **Email history search**: Display tickets assigned or previously assigned to a specific email
- 🎨 **Colorful interface**: Terminal display with colors and visual indicators
- ⚡ **Loading spinner**: Progress indicator during API requests

## 🔧 Installation

### Prerequisites

- Ruby 3.4.5 or higher
- Bundler
- Access to a Jira instance with API token

### Installation Steps

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd jiramanager
   ```

2. **Install dependencies**

   ```bash
   bundle install
   ```

3. **Configuration**

   ```bash
   cp conf/jiramanager-config.yml.template conf/jiramanager-config.yml
   ```

4. **Edit the configuration**

   ```yaml
   # conf/jiramanager-config.yml
   jira_secret: 'Basic YOUR_BASE64_ENCODED_API_TOKEN'
   jira_baseurl: 'https://your-domain.atlassian.net'
   ```

### Jira API Token Generation

1. Go to: <https://id.atlassian.com/manage-profile/security/api-tokens>
2. Create a new API token
3. Encode your credentials in Base64:

   ```bash
   echo -n "email:api_token" | base64
   ```

   Replace `email` with your Jira email and `api_token` with your generated token

4. Prefix with "Basic " in the configuration

## 🚀 Usage

### Basic Command

```bash
./bin/jiramanager
```

### Available Options

| Option | Description |
|--------|-------------|
| `-e, --email EMAIL` | List tickets assigned to the specified email |
| `-a, --assigned-or-was EMAIL` | List tickets assigned or was assigned to the specified email |
| `-h, --help` | Show help message |

### Usage Examples

```bash
# Display your own assigned tickets
./bin/jiramanager

# Display tickets assigned to a specific email
./bin/jiramanager --email john.doe@example.com

# Display tickets assigned or was assigned to a specific email
./bin/jiramanager --assigned-or-was john.doe@example.com

# Show help
./bin/jiramanager --help
```

## 📁 Project Structure

```text
jiramanager/
├── bin/
│   └── jiramanager              # Main entry point
├── conf/
│   ├── jiramanager-config.yml   # Configuration (to be created)
│   └── jiramanager-config.yml.template
├── lib/
│   ├── jiramanager.rb           # Main class
│   └── jiramanager/
│       ├── api_jira.rb          # Jira API client
│       └── tools.rb             # Utilities (colors, UI)
├── Gemfile                      # Ruby dependencies
└── README.md
```

## 🔌 API and Classes

### Main Class: `Jiramanager`

- Configuration management
- Orchestration of different functionalities
- Error handling and timing

### Module `Tools`

- Terminal colorization functions
- Interactive user interface
- Spinners and progress indicators

### Class `ApiJira`

- Communication with Jira REST API v3
- Pagination handling
- Ticket data formatting

## 🛠️ Development

### Linter and Style

The project uses RuboCop to maintain code quality:

```bash
# Check style
rubocop

# Auto-correct
rubocop -a
```

### Tests

```bash
# Run tests (if present)
bundle exec rspec
```

## 📋 Requirements

- **Ruby**: 3.4.5+
- **Jira**: REST API v3
- **Permissions**: Read access to assigned tickets

## 🔒 Security

- ⚠️ **Never commit the `conf/jiramanager-config.yml` file**
- 🔐 Use API tokens instead of passwords
- 🛡️ Restrict token permissions to minimum requirements

## 🐛 Troubleshooting

### Common Errors

1. **Authentication Error**
   - Verify that the API token is valid
   - Ensure Base64 encoding is correct

2. **Connection Timeout**
   - Check the Jira base URL
   - Verify network connectivity

3. **No Tickets Found**
   - Verify that you have assigned tickets
   - Check your Jira account permissions

## 📝 Changelog

### Current Version

- ✅ Retrieval of tickets assigned to current user
- ✅ Retrieval of tickets assigned to a specific email
- ✅ Colorful interface with loading spinner
- ✅ YAML file configuration
- ✅ Error handling

## 🤝 Contributing

1. Fork the project
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the [MIT](LICENSE) License - see the LICENSE file for details.

## 👨‍💻 Author

- **Developer**: saumon™
- **Repository**: [[repository link](https://github.com/saumon/jiramanager)]

---

**⚡ Tip**: Add `./bin/jiramanager` to your PATH to use it from anywhere!
