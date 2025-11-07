enum PlugType {
  fan('Fan'),
  refrigerator('Refrigerator'),
  oven('Oven'),
  tv('TV'),
  ac('Air Conditioner'),
  washer('Washer'),
  custom('Custom');

  final String label;
  const PlugType(this.label);
}

// Provide a default ordered list for the UI to render as cards
const defaultPlugTypes = <PlugType>[
  PlugType.fan,
  PlugType.refrigerator,
  PlugType.oven,
  PlugType.tv,
  PlugType.ac,
  PlugType.washer,
  PlugType.custom,
];
