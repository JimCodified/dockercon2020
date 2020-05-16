## Part 2: Fixing User Instructions

* /usr/local/lib/ruby/site_ruby/2.7.0/rubygems/core_ext/kernel_gem.rb:67:in `synchronize': deadlock; recursive locking (ThreadError)
  * Seems related to wrong version of ruby (2.5 in original -- need to go to 2.7)