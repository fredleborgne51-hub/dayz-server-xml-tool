# DSXT — DayZ Server XML Tool

DSXT is a Bash tool for managing custom XML blocks in DayZ server missions.

[Version Française](README_FR.md)

## Purpose

DayZ server administrators may need to restore, update, compare, or reorganize custom XML entries after game updates or configuration changes. DSXT manages this work using XML fragments prepared in advance.

It can also be used to apply a specific XML configuration for a temporary event.

DSXT does **not** detect installed mods or generate XML configuration automatically. Administrators remain responsible for preparing the fragments.

## Features

- Add or replace custom XML blocks.
- Remove specific blocks or remove blocks by tag across mission XML files.
- Compare custom blocks with their source fragments.
- List and extract custom blocks.
- Synchronize blocks against a reference list.
- Validate mission XML files.

## Requirements

- Bash
- `xmllint` for XML validation
- A DayZ server mission containing the XML files to manage

## Installation

Place `dsxt.sh` in the directory containing your DayZ server directories.

Create a `dsxt/` directory inside each server directory. This directory stores that server's XML fragments and synchronization list files.

Example layout:

```text
/home/dayz/servers/
├── dsxt.sh
├── dayz-server-chernarus/
│   └── dsxt/
├── dayz-server-livonia/
│   └── dsxt/
└── dayz-server-sakhal/
    └── dsxt/
```

Make the script executable:

```bash
chmod +x dsxt.sh
```

Adapt the paths in the script if your directory layout differs.

## Preparing XML fragments

Each fragment follows the naming convention `TAG_target.xml`.

- `TAG` identifies the custom configuration.
- `target.xml` is the name of the mission XML file to modify.

Example fragment: `CODE-LOCK_types.xml`, stored in `dayz-server-chernarus/dsxt/`:

```xml
<type name="CodeLock">
    <nominal>10</nominal>
    <lifetime>7200</lifetime>
    <restock>0</restock>
    <min>5</min>
    <quantmin>-1</quantmin>
    <quantmax>-1</quantmax>
    <cost>100</cost>
    <flags count_in_cargo="0" count_in_hoarder="0" count_in_map="1" count_in_player="0" crafted="0" deloot="0"/>
    <category name="tools"/>
    <usage name="Industrial"/>
    <usage name="Farm"/>
</type>
```

A fragment contains only the XML entries to insert. Do not include an XML declaration, an additional root element such as `<types>`, or DSXT `CUSTOM` markers.

The entries must be suitable for the target mission XML file. Fragments can be organized by mod or grouped according to your needs.

## Usage

```text
Usage: ./dsxt.sh [-e|-E|-c|-l|-V|-x|-f|-h] SERVERLIST [FILELIST|TAG|TAGS|LIST]
       -e targeted deletion | -E global deletion by TAG
       -c compare | -l list
       -V validate | -x extract | -f synchronize | -h help
       -f and -x: single server only
```

### Command examples

```bash
./dsxt.sh SERVERLIST FILELIST
./dsxt.sh -e SERVERLIST FILELIST
./dsxt.sh -E SERVERLIST TAGS
./dsxt.sh -c SERVERLIST FILELIST
./dsxt.sh -l SERVERLIST
./dsxt.sh -V SERVERLIST
./dsxt.sh -x SERVER TAG
./dsxt.sh -f SERVER LIST
./dsxt.sh -h
```

- `SERVERLIST`: comma-separated list of server directories.
- `FILELIST`: comma-separated list of XML fragment filenames.
- `TAG` / `TAGS`: one tag or a comma-separated list of tags.
- `LIST`: synchronization list filename stored in the selected server's `dsxt/` directory. Its name and extension are unrestricted.

Use `./dsxt.sh -h` for the complete help and option details.

## Synchronizing blocks with a reference list

The `-f` option uses a reference list stored in the server's `dsxt/` directory. The filename and extension are unrestricted.

The list contains one source filename per line. Blank lines and lines beginning with `#` are ignored.

Example: `normal.conf`

```text
# Reference configuration
SOCLE_types.xml
CODE-LOCK_types.xml
TDM_cfgspawnabletypes.xml
```

## Multiple servers

When a command targets multiple servers, every requested source file must exist in the `dsxt/` directory of **each selected server**.

The contents of these files may differ between servers; each server uses its own fragment. If a requested source file is missing from any selected server, the preliminary checks fail and no changes are made.

## Related project

See the [DayZ Linux Server Guide](https://github.com/fredleborgne51-hub/dayz-linux-server-guide) for information about setting up and administering a DayZ dedicated server on Linux.

## License

DSXT is distributed under the MIT License. See [LICENSE](LICENSE) for details.
