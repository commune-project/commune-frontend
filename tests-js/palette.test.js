import assert from 'node:assert/strict';
import fs from 'node:fs';
import test from 'node:test';

const css = fs.readFileSync(new URL('../src/style.css', import.meta.url), 'utf8');

const tokens = Object.fromEntries(
  [...css.matchAll(/--([a-z0-9-]+)\s*:\s*(#[0-9a-f]{3,8})\s*;/gi)]
    .map(([, name, value]) => [name, value])
);

const channels = value => {
  const hex = value.slice(1);
  const expanded = hex.length === 3 ? [...hex].map(character => character + character).join('') : hex;
  assert.equal(expanded.length, 6, `unsupported color value ${value}`);
  return [0, 2, 4].map(offset => parseInt(expanded.slice(offset, offset + 2), 16) / 255);
};

const luminance = value => {
  const [red, green, blue] = channels(value).map(channel =>
    channel <= 0.03928 ? channel / 12.92 : ((channel + 0.055) / 1.055) ** 2.4
  );
  return 0.2126 * red + 0.7152 * green + 0.0722 * blue;
};

const contrast = (first, second) => {
  const values = [luminance(first), luminance(second)].sort((left, right) => right - left);
  return (values[0] + 0.05) / (values[1] + 0.05);
};

const token = name => {
  assert.ok(tokens[name], `missing palette token --${name}`);
  return tokens[name];
};

const format = (first, second) => `${contrast(first, second).toFixed(2)}:1`;

test('each application bar stop keeps white text above 4.5:1', () => {
  for (const stop of ['md-top-bar-start', 'md-top-bar-mid', 'md-top-bar-end']) {
    const background = token(stop);
    assert.ok(
      contrast(background, token('md-on-top-bar')) >= 4.5,
      `${stop} (${background}) only reaches ${format(background, token('md-on-top-bar'))}`
    );
  }
});

test('the on-bar focus ring stays above 3:1 on every bar stop', () => {
  for (const stop of ['md-top-bar-start', 'md-top-bar-mid', 'md-top-bar-end']) {
    const background = token(stop);
    assert.ok(
      contrast(background, token('md-focus-on-dark')) >= 3,
      `${stop} focus ring only reaches ${format(background, token('md-focus-on-dark'))}`
    );
  }
});

test('accent text stays above 4.5:1 on the page surface', () => {
  const surface = token('md-surface');
  assert.ok(
    contrast(surface, token('md-accent')) >= 4.5,
    `accent text only reaches ${format(surface, token('md-accent'))}`
  );
});

test('the error color stays above 4.5:1 on the page surface', () => {
  const surface = token('md-surface');
  assert.ok(
    contrast(surface, token('md-error')) >= 4.5,
    `error text only reaches ${format(surface, token('md-error'))}`
  );
});
