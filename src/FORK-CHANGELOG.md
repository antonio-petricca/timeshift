# Fork changelog

## Done

- **BackupDeviceBox.vala**
  - Allowed discovery of LVM partitions.
  - Replaced disk label shown as 'disk size' with 'partition name'. The size is already shown in another column.
  - Added UUID column.
- **Device.vala**
  - LVM partitions, splitted among multiple devices, are no more added multiple times.
- **Main.vala**
  - Allowed writable loopback devices.
- **MountEntry.vala**
  - Added _read_only_ property.
- **SettingsWindow.vala**
  - Extended width to 640 to fit the added UUID column.

## Todo

- Show right free disk space.
- Fix snapshot partition click selection.