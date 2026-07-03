"""Map FIFA / SoFIFA nationality names to ISO 3166-1 alpha-2 codes."""

from __future__ import annotations

from typing import Optional

NATIONALITY_TO_ISO: dict[str, str] = {
    'argentina': 'AR',
    'brazil': 'BR',
    'portugal': 'PT',
    'spain': 'ES',
    'france': 'FR',
    'germany': 'DE',
    'italy': 'IT',
    'england': 'GB',
    'netherlands': 'NL',
    'belgium': 'BE',
    'croatia': 'HR',
    'uruguay': 'UY',
    'colombia': 'CO',
    'mexico': 'MX',
    'united states': 'US',
    'usa': 'US',
    'poland': 'PL',
    'serbia': 'RS',
    'switzerland': 'CH',
    'denmark': 'DK',
    'sweden': 'SE',
    'norway': 'NO',
    'austria': 'AT',
    'turkey': 'TR',
    'türkiye': 'TR',
    'morocco': 'MA',
    'senegal': 'SN',
    'nigeria': 'NG',
    'ghana': 'GH',
    'cameroon': 'CM',
    'ivory coast': 'CI',
    "cote d'ivoire": 'CI',
    'japan': 'JP',
    'korea republic': 'KR',
    'south korea': 'KR',
    'australia': 'AU',
    'scotland': 'GB',
    'wales': 'GB',
    'ukraine': 'UA',
    'russia': 'RU',
    'czech republic': 'CZ',
    'czechia': 'CZ',
    'greece': 'GR',
    'romania': 'RO',
    'hungary': 'HU',
    'ireland': 'IE',
    'republic of ireland': 'IE',
    'finland': 'FI',
    'iceland': 'IS',
    'paraguay': 'PY',
    'chile': 'CL',
    'peru': 'PE',
    'ecuador': 'EC',
    'venezuela': 'VE',
    'bolivia': 'BO',
    'costa rica': 'CR',
    'egypt': 'EG',
    'algeria': 'DZ',
    'tunisia': 'TN',
    'south africa': 'ZA',
    'china pr': 'CN',
    'china': 'CN',
    'iran': 'IR',
    'saudi arabia': 'SA',
    'qatar': 'QA',
    'uae': 'AE',
    'canada': 'CA',
}


def nationality_to_iso(raw: Optional[str]) -> Optional[str]:
    if not raw or not str(raw).strip():
        return None
    value = str(raw).strip().lower()
    if len(value) == 2 and value.isalpha():
        return value.upper()
    return NATIONALITY_TO_ISO.get(value)
