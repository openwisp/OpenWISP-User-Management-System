# Loads OWMW configuration

OWMW = YAML.load_file(File.join(Rails.root, "config", "owmw.yml"))[Rails.env] rescue {}