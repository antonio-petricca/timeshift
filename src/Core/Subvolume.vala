/*
 * Subvolume.vala
 *
 * Copyright 2012-2018 Tony George <teejeetech@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 *
 */

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.JsonHelper;
using TeeJee.ProcessHelper;
using TeeJee.GtkHelper;
using TeeJee.System;
using TeeJee.Misc;

public class Subvolume : GLib.Object{

	public string device_uuid;
	public string name = "";
	public string path = "";
	public long id = -1;
	public int64 total_bytes = 0;
	public int64 unshared_bytes = 0;

	//parent
	public SnapshotRepo? repo;
	
	public Subvolume(string name, string path, string parent_dev_uuid, SnapshotRepo? parent_repo){
		this.name = name;
		this.path = path;
		this.device_uuid = parent_dev_uuid;
		this.repo = parent_repo;
	}

	public string total_formatted{
		owned get{
			return format_file_size(total_bytes);
		}
	}

	public string unshared_formatted{
		owned get{
			return format_file_size(unshared_bytes);
		}
	}

	public Device? get_device(){
		
		return Device.get_device_by_uuid(device_uuid);
	}
	
	public static Gee.HashMap<string, Subvolume> detect_subvolumes_for_system_by_path(
		string system_path, SnapshotRepo? repo, Gtk.Window? parent_window){

		var map = new Gee.HashMap<string, Subvolume>();
		
		log_debug("Searching subvolume for system at path: %s".printf(system_path));
		
		var fstab = FsTabEntry.read_file(path_combine(system_path, "/etc/fstab"));
		var crypttab = CryptTabEntry.read_file(path_combine(system_path, "/etc/crypttab"));
		
		foreach(var item in fstab){
			
			if (!item.is_for_system_directory()){ continue; }
			
			if (item.subvolume_name().length > 0){
				
				var dev = item.resolve_device(crypttab, parent_window);
				var dev_name = (dev == null) ? "" : dev.device;
				var dev_uuid = (dev == null) ? "" : dev.uuid;
				
				log_debug("Found subvolume: %s, on device: %s".printf(item.subvolume_name(), dev_name));
				
				var subvol = new Subvolume(item.subvolume_name(), item.mount_point, dev_uuid, repo);
				map.set(subvol.name, subvol);
			}
		}

		return map;
	}

	public void print_info(){
		
		log_debug("name=%s, uuid=%s, id=%ld, path=%s".printf(name, device_uuid, id, path));
	}

	public bool remove(){
		
		string cmd = "";
		string std_out;
		string std_err;
		int ret_val;

		print_info();
		
		if (!dir_exists(path)){
			return true; // ok, item does not exist
		}

		App.progress_text = _("Deleting subvolume")+ ": %s".printf(name);
		log_debug(App.progress_text);

		string options = App.use_option_raw ? "--commit-after" : "";
		
		cmd = "btrfs subvolume delete %s '%s'".printf(options, path);
		log_debug(cmd);
		ret_val = exec_sync(cmd, out std_out, out std_err);
		if (ret_val != 0){
			log_error(_("Failed to delete snapshot subvolume") + ": '%s'".printf(path));
			return false;
		}

		log_msg(_("Deleted subvolume") + ": %s (id %ld)".printf(name, id));

		if ((id > 0) && (repo != null)){

			log_debug(_("Destroying qgroup")+ ": 0/%ld".printf(id));
			
			cmd = "btrfs qgroup destroy 0/%ld '%s'".printf(id, repo.mount_paths[name]);
			log_debug(cmd);
			ret_val = exec_sync(cmd, out std_out, out std_err);
			if (ret_val != 0){
				log_error(_("Failed to destroy qgroup") + ": '0/%ld'".printf(id));
				return false;
			}

			log_msg(_("Destroyed qgroup") + ": 0/%ld".printf(id));
		}

		return true;
	}
}
