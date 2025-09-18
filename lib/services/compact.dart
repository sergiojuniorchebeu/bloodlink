class Compat {
  static bool donorCanGiveTo(String dG, String dRh, String rG, String rRh) {
    // Groupes: O, A, B, AB — Rh: +|-
    final g = dG.toUpperCase(); final r = rG.toUpperCase();
    final rhOk = (dRh == '-') || (dRh == '+' && rRh == '+');
    bool gOk;
    switch (g) {
      case 'O': gOk = true; break;
      case 'A': gOk = r == 'A' || r == 'AB'; break;
      case 'B': gOk = r == 'B' || r == 'AB'; break;
      case 'AB': gOk = r == 'AB'; break;
      default: gOk = false;
    }
    return gOk && rhOk;
  }
}
