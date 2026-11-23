#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw(abs_path);
use IO::Socket::INET;

# Servidor estático mínimo usado solamente como alternativa local con Git Bash.
my ($port, $root) = @ARGV;
die "Uso: servidor.pl PUERTO DIRECTORIO\n" unless $port && $root;
$root = abs_path($root) or die "No se encontró el directorio raíz\n";
my $server = IO::Socket::INET->new(
  LocalAddr => '127.0.0.1', LocalPort => $port, Proto => 'tcp', Listen => 5, ReuseAddr => 1
) or die "No se pudo iniciar el servidor: $!\n";

while (my $client = $server->accept()) {
  my $request = <$client> // '';
  $request =~ m{^(?:GET|HEAD)\s+([^\s?]+)};
  my $path = $1 // '/';
  $path = '/index.html' if $path eq '/';
  $path =~ s{%([0-9A-Fa-f]{2})}{chr(hex($1))}eg;
  $path =~ s{^/+}{};
  my $file = abs_path("$root/$path");
  if (defined $file && index($file, $root) == 0 && -f $file) {
    open my $fh, '<:raw', $file or die "No se pudo leer $file: $!";
    local $/;
    my $body = <$fh>;
    close $fh;
    print $client "HTTP/1.1 200 OK\r\nContent-Length: " . length($body) . "\r\nConnection: close\r\n\r\n$body";
  } else {
    print $client "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n";
  }
  close $client;
}
