# This file is generated by Dist::Zilla::Plugin::CPANFile v6.030
# Do not edit this file directly. To change prereqs, edit the `dist.ini` file.

requires "CHI" => "0";
requires "CLI::Helpers" => "0";
requires "Capture::Tiny" => "0";
requires "DBIx::Connector" => "0";
requires "Getopt::Long::Descriptive" => "0";
requires "Hash::Merge::Simple" => "0";
requires "JSON::MaybeXS" => "0";
requires "List::Util" => "0";
requires "MaxMind::DB::Reader" => "0";
requires "Module::Load" => "0";
requires "Module::Pluggable::Object" => "0";
requires "Moo" => "0";
requires "Moo::Role" => "0";
requires "Net::DNS" => "0";
requires "Ref::Util" => "0";
requires "Socket" => "0";
requires "Storable" => "0";
requires "Sub::Exporter" => "0";
requires "Time::HiRes" => "0";
requires "Types::Standard" => "0";
requires "YAML::XS" => "0";
requires "namespace::autoclean" => "0";
requires "perl" => "v5.16.0";
requires "warnings" => "0";

on 'test' => sub {
  requires "DDP" => "0";
  requires "File::Spec" => "0";
  requires "File::Temp" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Net::DNS::Nameserver" => "0";
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::Deep" => "0";
  requires "Test::More" => "0";
  requires "Test::Perl::Critic" => "0";
  requires "Test::SharedFork" => "0";
  requires "perl" => "v5.16.0";
  requires "strict" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "perl" => "v5.16.0";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::EOL" => "0";
  requires "Test::More" => "0.88";
  requires "Test::Perl::Critic" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "strict" => "0";
};
