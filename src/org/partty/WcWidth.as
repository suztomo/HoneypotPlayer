/*
 * org.partty.WcWidth
 *
 * This is an ported implementation of wcwidth() and wcswidth().
 *
 * FURUHASHI Sadayuki -- 2008-03-01
 *
 * Permission to use, copy, modify, and distribute this software
 * for any purpose and without fee is hereby granted. The author
 * disclaims all warranties with regard to this software.
 */

/*
 * This is an implementation of wcwidth() and wcswidth() (defined in
 * IEEE Std 1002.1-2001) for Unicode.
 *
 * http://www.opengroup.org/onlinepubs/007904975/functions/wcwidth.html
 * http://www.opengroup.org/onlinepubs/007904975/functions/wcswidth.html
 *
 * In fixed-width output devices, Latin characters all occupy a single
 * "cell" position of equal width, whereas ideographic CJK characters
 * occupy two such cells. Interoperability between terminal-line
 * applications and (teletype-style) character terminals using the
 * UTF-8 encoding requires agreement on which character should advance
 * the cursor by how many cell positions. No established formal
 * standards exist at present on which Unicode character shall occupy
 * how many cell positions on character terminals. These routines are
 * a first attempt of defining such behavior based on simple rules
 * applied to data provided by the Unicode Consortium.
 *
 * For some graphical characters, the Unicode standard explicitly
 * defines a character-cell width via the definition of the East Asian
 * FullWidth (F), Wide (W), Half-width (H), and Narrow (Na) classes.
 * In all these cases, there is no ambiguity about which width a
 * terminal shall use. For characters in the East Asian Ambiguous (A)
 * class, the width choice depends purely on a preference of backward
 * compatibility with either historic CJK or Western practice.
 * Choosing single-width for these characters is easy to justify as
 * the appropriate long-term solution, as the CJK practice of
 * displaying these characters as double-width comes from historic
 * implementation simplicity (8-bit encoded characters were displayed
 * single-width and 16-bit ones double-width, even for Greek,
 * Cyrillic, etc.) and not any typographic considerations.
 *
 * Much less clear is the choice of width for the Not East Asian
 * (Neutral) class. Existing practice does not dictate a width for any
 * of these characters. It would nevertheless make sense
 * typographically to allocate two character cells to characters such
 * as for instance EM SPACE or VOLUME INTEGRAL, which cannot be
 * represented adequately with a single-width glyph. The following
 * routines at present merely assign a single-cell width to all
 * neutral characters, in the interest of simplicity. This is not
 * entirely satisfactory and should be reconsidered before
 * establishing a formal standard in this area. At the moment, the
 * decision which Not East Asian (Neutral) characters should be
 * represented by double-width glyphs cannot yet be answered by
 * applying a simple rule from the Unicode database content. Setting
 * up a proper standard for the behavior of UTF-8 character terminals
 * will require a careful analysis not only of each Unicode character,
 * but also of each presentation form, something the author of these
 * routines has avoided to do so far.
 *
 * http://www.unicode.org/unicode/reports/tr11/
 *
 * Markus Kuhn -- 2007-05-25 (Unicode 5.0)
 *
 * Permission to use, copy, modify, and distribute this software
 * for any purpose and without fee is hereby granted. The author
 * disclaims all warranties with regard to this software.
 *
 * Latest version: http://www.cl.cam.ac.uk/~mgk25/ucs/wcwidth.c
 */

package org.partty
{

public class WcWidth {


  /* The following two functions define the column width of an ISO 10646
   * character as follows:
   *
   *    - The null character (U+0000) has a column width of 0.
   *
   *    - Other C0/C1 control characters and DEL will lead to a return
   *      value of -1.
   *
   *    - Non-spacing and enclosing combining characters (general
   *      category code Mn or Me in the Unicode database) have a
   *      column width of 0.
   *
   *    - SOFT HYPHEN (U+00AD) has a column width of 1.
   *
   *    - Other format characters (general category code Cf in the Unicode
   *      database) and ZERO WIDTH SPACE (U+200B) have a column width of 0.
   *
   *    - Hangul Jamo medial vowels and final consonants (U+1160-U+11FF)
   *      have a column width of 0.
   *
   *    - Spacing characters in the East Asian Wide (W) or East Asian
   *      Full-width (F) category as defined in Unicode Technical
   *      Report #11 have a column width of 2.
   *
   *    - All remaining characters (including all printable
   *      ISO 8859-1 and WGL4 characters, Unicode control characters,
   *      etc.) have a column width of 1.
   *
   * This implementation assumes that wchar_t characters are encoded
   * in ISO 10646.
   */

  public static function mk_wcwidth(ucs:uint):int
  {
    var cmp:uint = ucs;

    /* test for 8-bit control characters */
    if (cmp == 0)
      return 0;
    if (cmp < 32 || (cmp >= 0x7f && cmp < 0xa0))
      return -1;

    /* binary search in table of non-spacing characters */
    if (bisearch(cmp, combining))
      return 0;

    /* if we arrive here, cmp is not a combining or C0/C1 control character */

    return 1 +
      (cmp >= 0x1100 &&
       (cmp <= 0x115f ||                    /* Hangul Jamo init. consonants */
        cmp == 0x2329 || cmp == 0x232a ||
        (cmp >= 0x2e80 && cmp <= 0xa4cf &&
         cmp != 0x303f) ||                  /* CJK ... Yi */
        (cmp >= 0xac00 && cmp <= 0xd7a3) || /* Hangul Syllables */
        (cmp >= 0xf900 && cmp <= 0xfaff) || /* CJK Compatibility Ideographs */
        (cmp >= 0xfe10 && cmp <= 0xfe19) || /* Vertical forms */
        (cmp >= 0xfe30 && cmp <= 0xfe6f) || /* CJK Compatibility Forms */
        (cmp >= 0xff00 && cmp <= 0xff60) || /* Fullwidth Forms */
        (cmp >= 0xffe0 && cmp <= 0xffe6) ||
        (cmp >= 0x20000 && cmp <= 0x2fffd) ||
        (cmp >= 0x30000 && cmp <= 0x3fffd)));
  }

  /*
  public static function mk_wcswidth(pwcs:String, size_t n):int
  {
    var w:int;
    var width:int = 0;

    for (;*pwcs && n-- > 0; pwcs++)
      if ((w = mk_wcwidth(*pwcs)) < 0)
        return -1;
      else
        width += w;

    return width;
  }
  */

  /*
   * The following functions are the same as mk_wcwidth() and
   * mk_wcwidth_cjk(), except that spacing characters in the East Asian
   * Ambiguous (A) category as defined in Unicode Technical Report #11
   * have a column width of 2. This variant might be useful for users of
   * CJK legacy encodings who want to migrate to UCS without changing
   * the traditional terminal character-width behaviour. It is not
   * otherwise recommended for general use.
   */
  public static function mk_wcwidth_cjk(ucs:uint):int
  {
    /* binary search in table of non-spacing characters */
    if (bisearch(ucs, ambiguous))
      return 2;

    return mk_wcwidth(ucs);
  }

  /*
  public static function mk_wcswidth_cjk(pwcs:String, size_t n):int
  {
    var w:int;
    var width:int = 0;

    for (;*pwcs && n-- > 0; pwcs++)
      if ((w = mk_wcwidth_cjk(*pwcs)) < 0)
        return -1;
      else
        width += w;

    return width;
  }
  */

  /* auxiliary function for binary search in interval table */
  private static function bisearch(ucs:uint, table:Array):Boolean
  {
    var min:int = 0;
    var mid:int;
    var max:int = table.length - 1;

    if (ucs >= table[0].first && ucs <= table[max].last) {
      while (max >= min) {
        mid = (min + max) / 2;
        if (ucs > table[mid].last)
          min = mid + 1;
        else if (ucs < table[mid].first)
          max = mid - 1;
        else
          return true;
      }
    }

    return false;
  }


}

}  // package


class Interval {
	private var _first:uint;
	private var _last:uint;
	public function Interval(first:uint, last:uint):void
	{
		_first = first;
		_last = last;
	}
	public function get first():uint
	{
		return _first;
	}
	public function get last():uint
	{
		return _last;
	}
}

function v(first:uint, last:uint):Interval
{
  return new Interval(first, last);
}

/* sorted list of non-overlapping intervals of non-spacing characters */
/* generated by
 *	uniset +cat=Me +cat=Mn +cat=Cf -00AD +1160-11FF +200B c
 */
const combining:Array = [
  v( 0x0300, 0x036F ), v( 0x0483, 0x0486 ), v( 0x0488, 0x0489 ),
  v( 0x0591, 0x05BD ), v( 0x05BF, 0x05BF ), v( 0x05C1, 0x05C2 ),
  v( 0x05C4, 0x05C5 ), v( 0x05C7, 0x05C7 ), v( 0x0600, 0x0603 ),
  v( 0x0610, 0x0615 ), v( 0x064B, 0x065E ), v( 0x0670, 0x0670 ),
  v( 0x06D6, 0x06E4 ), v( 0x06E7, 0x06E8 ), v( 0x06EA, 0x06ED ),
  v( 0x070F, 0x070F ), v( 0x0711, 0x0711 ), v( 0x0730, 0x074A ),
  v( 0x07A6, 0x07B0 ), v( 0x07EB, 0x07F3 ), v( 0x0901, 0x0902 ),
  v( 0x093C, 0x093C ), v( 0x0941, 0x0948 ), v( 0x094D, 0x094D ),
  v( 0x0951, 0x0954 ), v( 0x0962, 0x0963 ), v( 0x0981, 0x0981 ),
  v( 0x09BC, 0x09BC ), v( 0x09C1, 0x09C4 ), v( 0x09CD, 0x09CD ),
  v( 0x09E2, 0x09E3 ), v( 0x0A01, 0x0A02 ), v( 0x0A3C, 0x0A3C ),
  v( 0x0A41, 0x0A42 ), v( 0x0A47, 0x0A48 ), v( 0x0A4B, 0x0A4D ),
  v( 0x0A70, 0x0A71 ), v( 0x0A81, 0x0A82 ), v( 0x0ABC, 0x0ABC ),
  v( 0x0AC1, 0x0AC5 ), v( 0x0AC7, 0x0AC8 ), v( 0x0ACD, 0x0ACD ),
  v( 0x0AE2, 0x0AE3 ), v( 0x0B01, 0x0B01 ), v( 0x0B3C, 0x0B3C ),
  v( 0x0B3F, 0x0B3F ), v( 0x0B41, 0x0B43 ), v( 0x0B4D, 0x0B4D ),
  v( 0x0B56, 0x0B56 ), v( 0x0B82, 0x0B82 ), v( 0x0BC0, 0x0BC0 ),
  v( 0x0BCD, 0x0BCD ), v( 0x0C3E, 0x0C40 ), v( 0x0C46, 0x0C48 ),
  v( 0x0C4A, 0x0C4D ), v( 0x0C55, 0x0C56 ), v( 0x0CBC, 0x0CBC ),
  v( 0x0CBF, 0x0CBF ), v( 0x0CC6, 0x0CC6 ), v( 0x0CCC, 0x0CCD ),
  v( 0x0CE2, 0x0CE3 ), v( 0x0D41, 0x0D43 ), v( 0x0D4D, 0x0D4D ),
  v( 0x0DCA, 0x0DCA ), v( 0x0DD2, 0x0DD4 ), v( 0x0DD6, 0x0DD6 ),
  v( 0x0E31, 0x0E31 ), v( 0x0E34, 0x0E3A ), v( 0x0E47, 0x0E4E ),
  v( 0x0EB1, 0x0EB1 ), v( 0x0EB4, 0x0EB9 ), v( 0x0EBB, 0x0EBC ),
  v( 0x0EC8, 0x0ECD ), v( 0x0F18, 0x0F19 ), v( 0x0F35, 0x0F35 ),
  v( 0x0F37, 0x0F37 ), v( 0x0F39, 0x0F39 ), v( 0x0F71, 0x0F7E ),
  v( 0x0F80, 0x0F84 ), v( 0x0F86, 0x0F87 ), v( 0x0F90, 0x0F97 ),
  v( 0x0F99, 0x0FBC ), v( 0x0FC6, 0x0FC6 ), v( 0x102D, 0x1030 ),
  v( 0x1032, 0x1032 ), v( 0x1036, 0x1037 ), v( 0x1039, 0x1039 ),
  v( 0x1058, 0x1059 ), v( 0x1160, 0x11FF ), v( 0x135F, 0x135F ),
  v( 0x1712, 0x1714 ), v( 0x1732, 0x1734 ), v( 0x1752, 0x1753 ),
  v( 0x1772, 0x1773 ), v( 0x17B4, 0x17B5 ), v( 0x17B7, 0x17BD ),
  v( 0x17C6, 0x17C6 ), v( 0x17C9, 0x17D3 ), v( 0x17DD, 0x17DD ),
  v( 0x180B, 0x180D ), v( 0x18A9, 0x18A9 ), v( 0x1920, 0x1922 ),
  v( 0x1927, 0x1928 ), v( 0x1932, 0x1932 ), v( 0x1939, 0x193B ),
  v( 0x1A17, 0x1A18 ), v( 0x1B00, 0x1B03 ), v( 0x1B34, 0x1B34 ),
  v( 0x1B36, 0x1B3A ), v( 0x1B3C, 0x1B3C ), v( 0x1B42, 0x1B42 ),
  v( 0x1B6B, 0x1B73 ), v( 0x1DC0, 0x1DCA ), v( 0x1DFE, 0x1DFF ),
  v( 0x200B, 0x200F ), v( 0x202A, 0x202E ), v( 0x2060, 0x2063 ),
  v( 0x206A, 0x206F ), v( 0x20D0, 0x20EF ), v( 0x302A, 0x302F ),
  v( 0x3099, 0x309A ), v( 0xA806, 0xA806 ), v( 0xA80B, 0xA80B ),
  v( 0xA825, 0xA826 ), v( 0xFB1E, 0xFB1E ), v( 0xFE00, 0xFE0F ),
  v( 0xFE20, 0xFE23 ), v( 0xFEFF, 0xFEFF ), v( 0xFFF9, 0xFFFB ),
  v( 0x10A01, 0x10A03 ), v( 0x10A05, 0x10A06 ), v( 0x10A0C, 0x10A0F ),
  v( 0x10A38, 0x10A3A ), v( 0x10A3F, 0x10A3F ), v( 0x1D167, 0x1D169 ),
  v( 0x1D173, 0x1D182 ), v( 0x1D185, 0x1D18B ), v( 0x1D1AA, 0x1D1AD ),
  v( 0x1D242, 0x1D244 ), v( 0xE0001, 0xE0001 ), v( 0xE0020, 0xE007F ),
  v( 0xE0100, 0xE01EF )
];

/* sorted list of non-overlapping intervals of East Asian Ambiguous
 * characters, generated by
 *
 * uniset +WIDTH-A -cat=Me -cat=Mn -cat=Cf \
 *	+E000..F8FF \
 *	+F0000..FFFFD \
 *	+100000..10FFFD  c
 *
 * "WIDTH-A" is a file extracted from EastAsianWidth.txt by selecting
 * only those with width "A", and omitting:
 *
 *	0xAD
 *	all lines with "COMBINING"
 *
 * (uniset does not recognize the range expressions in WIDTH-A).
 */
const ambiguous:Array = [
  v( 0x00A1, 0x00A1 ), v( 0x00A4, 0x00A4 ), v( 0x00A7, 0x00A8 ),
  v( 0x00AA, 0x00AA ), v( 0x00AE, 0x00AE ), v( 0x00B0, 0x00B4 ),
  v( 0x00B6, 0x00BA ), v( 0x00BC, 0x00BF ), v( 0x00C6, 0x00C6 ),
  v( 0x00D0, 0x00D0 ), v( 0x00D7, 0x00D8 ), v( 0x00DE, 0x00E1 ),
  v( 0x00E6, 0x00E6 ), v( 0x00E8, 0x00EA ), v( 0x00EC, 0x00ED ),
  v( 0x00F0, 0x00F0 ), v( 0x00F2, 0x00F3 ), v( 0x00F7, 0x00FA ),
  v( 0x00FC, 0x00FC ), v( 0x00FE, 0x00FE ), v( 0x0101, 0x0101 ),
  v( 0x0111, 0x0111 ), v( 0x0113, 0x0113 ), v( 0x011B, 0x011B ),
  v( 0x0126, 0x0127 ), v( 0x012B, 0x012B ), v( 0x0131, 0x0133 ),
  v( 0x0138, 0x0138 ), v( 0x013F, 0x0142 ), v( 0x0144, 0x0144 ),
  v( 0x0148, 0x014B ), v( 0x014D, 0x014D ), v( 0x0152, 0x0153 ),
  v( 0x0166, 0x0167 ), v( 0x016B, 0x016B ), v( 0x01CE, 0x01CE ),
  v( 0x01D0, 0x01D0 ), v( 0x01D2, 0x01D2 ), v( 0x01D4, 0x01D4 ),
  v( 0x01D6, 0x01D6 ), v( 0x01D8, 0x01D8 ), v( 0x01DA, 0x01DA ),
  v( 0x01DC, 0x01DC ), v( 0x0251, 0x0251 ), v( 0x0261, 0x0261 ),
  v( 0x02C4, 0x02C4 ), v( 0x02C7, 0x02C7 ), v( 0x02C9, 0x02CB ),
  v( 0x02CD, 0x02CD ), v( 0x02D0, 0x02D0 ), v( 0x02D8, 0x02DB ),
  v( 0x02DD, 0x02DD ), v( 0x02DF, 0x02DF ), v( 0x0391, 0x03A1 ),
  v( 0x03A3, 0x03A9 ), v( 0x03B1, 0x03C1 ), v( 0x03C3, 0x03C9 ),
  v( 0x0401, 0x0401 ), v( 0x0410, 0x044F ), v( 0x0451, 0x0451 ),
  v( 0x2010, 0x2010 ), v( 0x2013, 0x2016 ), v( 0x2018, 0x2019 ),
  v( 0x201C, 0x201D ), v( 0x2020, 0x2022 ), v( 0x2024, 0x2027 ),
  v( 0x2030, 0x2030 ), v( 0x2032, 0x2033 ), v( 0x2035, 0x2035 ),
  v( 0x203B, 0x203B ), v( 0x203E, 0x203E ), v( 0x2074, 0x2074 ),
  v( 0x207F, 0x207F ), v( 0x2081, 0x2084 ), v( 0x20AC, 0x20AC ),
  v( 0x2103, 0x2103 ), v( 0x2105, 0x2105 ), v( 0x2109, 0x2109 ),
  v( 0x2113, 0x2113 ), v( 0x2116, 0x2116 ), v( 0x2121, 0x2122 ),
  v( 0x2126, 0x2126 ), v( 0x212B, 0x212B ), v( 0x2153, 0x2154 ),
  v( 0x215B, 0x215E ), v( 0x2160, 0x216B ), v( 0x2170, 0x2179 ),
  v( 0x2190, 0x2199 ), v( 0x21B8, 0x21B9 ), v( 0x21D2, 0x21D2 ),
  v( 0x21D4, 0x21D4 ), v( 0x21E7, 0x21E7 ), v( 0x2200, 0x2200 ),
  v( 0x2202, 0x2203 ), v( 0x2207, 0x2208 ), v( 0x220B, 0x220B ),
  v( 0x220F, 0x220F ), v( 0x2211, 0x2211 ), v( 0x2215, 0x2215 ),
  v( 0x221A, 0x221A ), v( 0x221D, 0x2220 ), v( 0x2223, 0x2223 ),
  v( 0x2225, 0x2225 ), v( 0x2227, 0x222C ), v( 0x222E, 0x222E ),
  v( 0x2234, 0x2237 ), v( 0x223C, 0x223D ), v( 0x2248, 0x2248 ),
  v( 0x224C, 0x224C ), v( 0x2252, 0x2252 ), v( 0x2260, 0x2261 ),
  v( 0x2264, 0x2267 ), v( 0x226A, 0x226B ), v( 0x226E, 0x226F ),
  v( 0x2282, 0x2283 ), v( 0x2286, 0x2287 ), v( 0x2295, 0x2295 ),
  v( 0x2299, 0x2299 ), v( 0x22A5, 0x22A5 ), v( 0x22BF, 0x22BF ),
  v( 0x2312, 0x2312 ), v( 0x2460, 0x24E9 ), v( 0x24EB, 0x254B ),
  v( 0x2550, 0x2573 ), v( 0x2580, 0x258F ), v( 0x2592, 0x2595 ),
  v( 0x25A0, 0x25A1 ), v( 0x25A3, 0x25A9 ), v( 0x25B2, 0x25B3 ),
  v( 0x25B6, 0x25B7 ), v( 0x25BC, 0x25BD ), v( 0x25C0, 0x25C1 ),
  v( 0x25C6, 0x25C8 ), v( 0x25CB, 0x25CB ), v( 0x25CE, 0x25D1 ),
  v( 0x25E2, 0x25E5 ), v( 0x25EF, 0x25EF ), v( 0x2605, 0x2606 ),
  v( 0x2609, 0x2609 ), v( 0x260E, 0x260F ), v( 0x2614, 0x2615 ),
  v( 0x261C, 0x261C ), v( 0x261E, 0x261E ), v( 0x2640, 0x2640 ),
  v( 0x2642, 0x2642 ), v( 0x2660, 0x2661 ), v( 0x2663, 0x2665 ),
  v( 0x2667, 0x266A ), v( 0x266C, 0x266D ), v( 0x266F, 0x266F ),
  v( 0x273D, 0x273D ), v( 0x2776, 0x277F ), v( 0xE000, 0xF8FF ),
  v( 0xFFFD, 0xFFFD ), v( 0xF0000, 0xFFFFD ), v( 0x100000, 0x10FFFD )
];


