# frozen_string_literal: true

require "sts"

module Glossarist
  module Sts
    autoload :ExtractedDesignation, "#{__dir__}/sts/extracted_designation"
    autoload :ExtractedLangSet,     "#{__dir__}/sts/extracted_lang_set"
    autoload :ExtractedTerm,        "#{__dir__}/sts/extracted_term"
    autoload :ImportResult,         "#{__dir__}/sts/import_result"
    autoload :Importer,             "#{__dir__}/sts/importer"
    autoload :TermExtractor,        "#{__dir__}/sts/term_extractor"
    autoload :TermMapper,           "#{__dir__}/sts/term_mapper"

    ISO_639_1_TO_639_2 = {
      "aa" => "aar", "ab" => "abk", "af" => "afr", "ak" => "aka",
      "am" => "amh", "an" => "arg", "ar" => "ara", "as" => "asm",
      "av" => "ava", "ay" => "aym", "az" => "aze", "ba" => "bak",
      "be" => "bel", "bg" => "bul", "bh" => "bih", "bi" => "bis",
      "bm" => "bam", "bn" => "ben", "bo" => "bod", "br" => "bre",
      "bs" => "bos", "ca" => "cat", "ce" => "che", "ch" => "cha",
      "co" => "cos", "cr" => "cre", "cs" => "ces", "cu" => "chu",
      "cv" => "chv", "cy" => "cym", "da" => "dan", "de" => "deu",
      "dv" => "div", "dz" => "dzo", "ee" => "ewe", "el" => "ell",
      "en" => "eng", "eo" => "epo", "es" => "spa", "et" => "est",
      "eu" => "eus", "fa" => "fas", "ff" => "ful", "fi" => "fin",
      "fj" => "fij", "fo" => "fao", "fr" => "fra", "fy" => "fry",
      "ga" => "gle", "gd" => "gla", "gl" => "glg", "gn" => "grn",
      "gu" => "guj", "gv" => "glv", "ha" => "hau", "he" => "heb",
      "hi" => "hin", "ho" => "hmo", "hr" => "hrv", "ht" => "hat",
      "hu" => "hun", "hy" => "hye", "hz" => "her", "ia" => "ina",
      "id" => "ind", "ie" => "ile", "ig" => "ibo", "ii" => "iii",
      "ik" => "ipk", "io" => "ido", "is" => "isl", "it" => "ita",
      "iu" => "iku", "ja" => "jpn", "jv" => "jav", "ka" => "kat",
      "kg" => "kon", "ki" => "kik", "kj" => "kua", "kk" => "kaz",
      "kl" => "kal", "km" => "khm", "kn" => "kan", "ko" => "kor",
      "kr" => "kau", "ks" => "kas", "ku" => "kur", "kv" => "kom",
      "kw" => "cor", "ky" => "kir", "la" => "lat", "lb" => "ltz",
      "lg" => "lug", "li" => "lim", "ln" => "lin", "lo" => "lao",
      "lt" => "lit", "lu" => "lub", "lv" => "lav", "mg" => "mlg",
      "mh" => "mah", "mi" => "mri", "mk" => "mkd", "ml" => "mal",
      "mn" => "mon", "mr" => "mar", "ms" => "msa", "mt" => "mlt",
      "my" => "mya", "na" => "nau", "nb" => "nob", "nd" => "nde",
      "ne" => "nep", "ng" => "ndo", "nl" => "nld", "nn" => "nno",
      "no" => "nor", "nr" => "nbl", "nv" => "nav", "ny" => "nya",
      "oc" => "oci", "oj" => "oji", "om" => "orm", "or" => "ori",
      "os" => "oss", "pa" => "pan", "pi" => "pli", "pl" => "pol",
      "ps" => "pus", "pt" => "por", "qu" => "que", "rm" => "roh",
      "rn" => "run", "ro" => "ron", "ru" => "rus", "rw" => "kin",
      "sa" => "san", "sc" => "srd", "sd" => "snd", "se" => "sme",
      "sg" => "sag", "si" => "sin", "sk" => "slk", "sl" => "slv",
      "sm" => "smo", "sn" => "sna", "so" => "som", "sq" => "sqi",
      "sr" => "srp", "ss" => "ssw", "st" => "sot", "su" => "sun",
      "sv" => "swe", "sw" => "swa", "ta" => "tam", "te" => "tel",
      "tg" => "tgk", "th" => "tha", "ti" => "tir", "tk" => "tuk",
      "tl" => "tgl", "tn" => "tsn", "to" => "ton", "tr" => "tur",
      "ts" => "tso", "tt" => "tat", "tw" => "twi", "ty" => "tah",
      "ug" => "uig", "uk" => "ukr", "ur" => "urd", "uz" => "uzb",
      "ve" => "ven", "vi" => "vie", "vo" => "vol", "wa" => "wln",
      "wo" => "wol", "xh" => "xho", "yi" => "yid", "yo" => "yor",
      "za" => "zha", "zh" => "zho", "zu" => "zul"
    }.freeze

    TERM_TYPE_MAP = {
      "acronym" => "abbreviation",
      "abbreviation" => "abbreviation",
      "fullForm" => "expression",
      "symbol" => "symbol",
      "variant" => "expression",
      "equation" => "expression",
      "formula" => "expression",
    }.freeze

    NORMATIVE_STATUS_MAP = {
      "preferredTerm" => "preferred",
      "admittedTerm" => "admitted",
      "deprecatedTerm" => "deprecated",
    }.freeze

    def self.convert_language_code(code)
      return code if code.nil?
      return code if code.length == 3

      ISO_639_1_TO_639_2[code] || code
    end
  end
end
