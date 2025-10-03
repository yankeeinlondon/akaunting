# Akaunting™

[![Release](https://img.shields.io/github/v/release/akaunting/akaunting?label=release)](https://github.com/akaunting/akaunting/releases)
![Downloads](https://img.shields.io/github/downloads/akaunting/akaunting/total?label=downloads)
[![Translations](https://badges.crowdin.net/akaunting/localized.svg)](https://crowdin.com/project/akaunting)
[![Tests](https://img.shields.io/github/actions/workflow/status/akaunting/akaunting/tests.yml?label=tests)](https://github.com/akaunting/akaunting/actions)

Online accounting software designed for small businesses and freelancers. Akaunting is built with modern technologies such as Laravel, VueJS, Tailwind, RESTful API etc. Thanks to its modular structure, Akaunting provides an awesome App Store for users and developers.

* [Home](https://akaunting.com) - The house of Akaunting
* [Forum](https://akaunting.com/forum) - Ask for support
* [Documentation](https://akaunting.com/hc/docs) - Learn how to use
* [Developer Portal](https://developer.akaunting.com) - Generate passive income
* [App Store](https://akaunting.com/apps) - Extend your Akaunting
* [Translations](https://crowdin.com/project/akaunting) - Help us translate Akaunting

## Requirements

* PHP 8.1 or higher
* Database (e.g.: MariaDB, MySQL, PostgreSQL, SQLite)
* Web Server (eg: Apache, Nginx, IIS)
* [Other libraries](https://akaunting.com/hc/docs/on-premise/requirements/)

## Framework

Akaunting uses [Laravel](http://laravel.com), the best existing PHP framework, as the foundation framework and [Module](https://github.com/akaunting/module) package for Apps.

## Installation

* Install [Composer](https://getcomposer.org/download) and [Npm](https://nodejs.org/en/download)
* Clone the repository: `git clone https://github.com/akaunting/akaunting.git`
* Install dependencies: `composer install ; npm install ; npm run dev`
* Install Akaunting:

```bash
php artisan install --db-name="akaunting" --db-username="root" --db-password="pass" --admin-email="admin@company.com" --admin-password="123456"
```

* Create sample data (optional): `php artisan sample-data:seed`

## Containerization

Akaunting provides Docker support for easy setup and deployment.

### Quick Start

**First-time setup** (⚠️ **This will delete existing data!**):

```bash
./scripts/initialize.sh
```

**Start existing installation** (preserves data):

```bash
./scripts/start.sh
```

### Access URLs

- **Application:** http://localhost:8000
- **phpMyAdmin:** http://localhost:8080
- **Default Login:** admin@company.com / 123456

### Important Notes

- `initialize.sh` - Use for **first-time setup only**. Deletes all existing data.
- `start.sh` - Use to **start/restart** an existing installation. Preserves data.
- Frontend assets must be built locally: `npm install --legacy-peer-deps && npm run production`

For detailed documentation, see [Containerization Guide](./docs/containerization.md).

### API Access

The self-hosted installation includes a full REST API for programmatic access to all features. See [API Documentation](./docs/api.md) for complete endpoint reference.

**Note**: This is separate from the "API Key" feature in the UI, which connects to Akaunting's cloud marketplace.

## Contributing

Please, be very clear on your commit messages and Pull Requests, empty Pull Request messages may be rejected without reason.

When contributing code to Akaunting, you must follow the PSR coding standards. The golden rule is: Imitate the existing Akaunting code.

Please note that this project is released with a [Contributor Code of Conduct](https://akaunting.com/conduct). *By participating in this project you agree to abide by its terms*.

## Translation

If you'd like to contribute translations, please check out our [Crowdin](https://crowdin.com/project/akaunting) project.

## Changelog

Please see [Releases](../../releases) for more information about what has changed recently.

## Security

Please review [our security policy](https://github.com/akaunting/akaunting/security/policy) on how to report security vulnerabilities.

## Credits

* [Denis Duliçi](https://github.com/denisdulici)
* [Cüneyt Şentürk](https://github.com/cuneytsenturk)
* [All Contributors](../../contributors)

## License

Akaunting is released under the [BSL license](LICENSE.txt).
