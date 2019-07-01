#tasks for out of band user management
#
desc "User Administration"
namespace :user do
  require 'bundler/setup'
  require 'securerandom'
  # Configure the process for the current cron configuration.
  require_relative '../lib/ncbo_cron'
  config_exists = File.exist?(File.expand_path('../../config/config.rb', __FILE__))
  abort("Please create a config/config.rb file using the config/config.rb.sample as a template") unless config_exists
  require_relative '../config/config'

  desc "Add administrator role to the user"
  task :adminify, [:username] do |t, args|
    username = args.username
    user = LinkedData::Models::User.find(username).first
    abort("FAILED: The user #{args.username} does not exist") if user.nil?
    user.bring_remaining
    user.valid?
    # Get an instance of the administrator role
    role = LinkedData::Models::Users::Role.find("ADMINISTRATOR").first.bring_remaining
    # Sanity check that you have a valid role
    role.valid?
    # Add the administrative role to the user's list of roles
    user_roles = user.role
    user_roles = user_roles.dup
    user_roles << role
    user.role = user_roles
    # Sanity check to make sure role was added properly
    user.valid?
    user.save
  end

  desc "Reset all roles to LIBRARIAN for the user"
  task :resetroles, [:username] do |t, args|
    username = args.username
    user = LinkedData::Models::User.find(username).first
    abort("FAILED: user #{args.username} does not exist") if user.nil?
    user.bring_remaining
    user.valid?
    # Get an instance of the administrator role
    role = LinkedData::Models::Users::Role.find("LIBRARIAN").first.bring_remaining
    # Sanity check that you have a valid role
    role.valid?
    user.role = [role]
    # Sanity check to make sure role was added properly
    user.valid?
    user.save
  end

  desc "Reset password to a random value for the user"
  task :resetpassword, [:username] do |t, args|
    username = args.username
    newpassword = SecureRandom.base64(15)
    user = LinkedData::Models::User.find(username).first
    abort("FAILED: user #{args.username} does not exist") if user.nil?
    user.bring_remaining
    user.password = newpassword
    user.valid?
    user.save
    puts "password for the user #{username} is reset to #{newpassword}"
  end

  desc "Create a new user"
  task :create, [:username, :email, :password ] do |t, args|
    args.with_defaults(:password => nil)
    password = args.password
    if args.password.nil?
      password = SecureRandom.base64(15)
    end
    checkuser = LinkedData::Models::User.find(args.username).first
    abort("FAILED: The user #{args.username} already exists") unless checkuser.nil?
    user = LinkedData::Models::User.new
    role = LinkedData::Models::Users::Role.find("LIBRARIAN").first.bring_remaining
    user.username = args.username
    user.email = args.email
    user.password = password
    user.role = [role]
    if user.valid?
      user.save
    else
      puts "FAILED: create new user"
   end
  end

  namespace :apikey do
    desc "get APIKEY for the user"
    task :get, [:username] do |t, args|
      user = LinkedData::Models::User.find(args.username).first
      abort("FAILED: The user #{args.username} does not exist") if user.nil?
      user.bring_remaining
      puts user.apikey
    end
    desc "reset APIKEY for the user"
        desc "reset APIKEY for the user to random value or to specified value if API key is provided"
    task :reset, [:username, :apikey] do |t, args|
      user = LinkedData::Models::User.find(args.username).first
      abort("FAILED: The user #{args.username} does not exist") if user.nil?
      user.bring_remaining
      if args.apikey.nil?
         apikey = SecureRandom.uuid
      else
         apikey = args.apikey
      end
      user.apikey = apikey
      if user.valid?
         user.save
      else
         puts "FAILED: reset api key"
      end
    end
  end
end
