/// Corner-radius scale for the redesign.
///
/// The previous UI used `BorderRadius.circular(8)` everywhere — the same
/// radius on a 24px badge and a 340px hero card. That reads flat and dated.
/// This scale gives each surface size its own rounding so bigger surfaces
/// feel softer and small controls stay crisp.
class AppRadii {
  const AppRadii._();

  /// Small controls: badges, chips, icon tiles, inline pills of copy.
  static const double sm = 12;

  /// Standard cards, list tiles, metric tiles, buttons with a label.
  static const double md = 18;

  /// Large hero panels — the one or two dominant surfaces on a screen.
  static const double lg = 26;

  /// Fully rounded: icon-only circular buttons, docks, stadium shapes.
  static const double pill = 999;
}
