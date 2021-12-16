#!/usr/bin/env ruby

require 'yaml'

$availCmd = ARGV[0]
$versionSets = YAML.load(`#{$availCmd} --sets`)

def versionHex(vers)
    major = 0;
    minor = 0;
    revision = 0;

    if vers =~ /^(\d+)$/
        major = $1.to_i;
    elsif vers =~ /^(\d+).(\d+)$/
        major = $1.to_i;
        minor = $2.to_i;
    elsif vers =~ /^(\d+).(\d+).(\d+)$/
        major = $1.to_i;
        minor = $2.to_i;
        revision = $3.to_i;
    end
    "0x00#{major.to_s(16).rjust(2, '0')}#{minor.to_s(16).rjust(2, '0')}#{revision.to_s(16).rjust(2, '0')}"
end

$versionLookupTable = {
    "spring" => "0301",
    "late_spring" => "0415",
    "summer" => "0601",
    "late_summer" => "0715",
    "fall" => "0901",
    "autumn" => "0902", # autumn has to come after fall because of ios 13.0 and 13.1
    "late_fall" => "1015",
    "winter" => "1201",
    "late_winter" => "1215"
}

def setNameToVersion(setName)
    if setName =~ /^(.*)\_(\d{4})$/
        if not $versionLookupTable.key?($1)
            abort("Unknown platform set substring \"#{$1}\"")
        end
        "0x00#{$2.to_i.to_s(16)}#{$versionLookupTable[$1]}"
    else
        abort("Could not parse set identiifer \"#{setName}\"")
    end
end

def expandVersionSets()
    puts $versionSets.map { |set, value|
        "\t{ .set = #{setNameToVersion(set)}, " + value.map { | platform, version |
            ".#{platform} = #{versionHex(version)}"
        }.sort.join(", ") + " }"
    }.join(",\n");
end



puts <<-HEADER
// This file is autogenerated for use only by dyld
// DO NOT USE
// DO NOT EDIT

#include <set>
#include <array>
namespace dyld3 {
struct __attribute__((visibility("hidden"))) VersionSetEntry {
    uint32_t set = 0;
    uint32_t bridgeos = 0;
    uint32_t ios = 0;
    uint32_t macos = 0;
    uint32_t tvos = 0;
    uint32_t watchos = 0;
    bool operator<(const uint32_t& other) const {
        return set < other;
    }
};

static const std::array<VersionSetEntry, #{$versionSets.size()}> sVersionMap = {{
HEADER

expandVersionSets()

puts <<-FOOTER
}};
};
FOOTER
