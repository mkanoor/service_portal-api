# Be sure to restart your server when you modify this file.
unless defined?(::Rails::Console)
  catalog_inventory_listener = CatalogInventory::EventListener.new(:host => ClowderConfig.queue_host, :port => ClowderConfig.queue_port)
  catalog_inventory_listener.run
end
