# -*- mode: ruby -*-
# vi: set ft=ruby :
 
def config_folders(instance, vm_id, apps, vagrant_ci_path)

  instance.vm.synced_folder ".", "/vagrant" # Always needed by the provisioning
  instance.vm.synced_folder vagrant_ci_path + "/provisioning", "/provisioning" # Always needed by the provisioning

  # Share folder if the "src" variable is set
  apps.each do |config|
    if config["run_in"] == vm_id and config["folder"] and config["folder"]["src"] then 
      instance.vm.synced_folder config["folder"]["src"], config["folder"]["dest"]
    end
  end if apps

end

