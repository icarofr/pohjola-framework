/**
 * Clone-from-live Feature wiring. Reads the current Route / I18n source
 * instead of baking one site's last codec clauses and language list.
 */
const BODY_BY_TAG = {
  en: (name) => `Explore our ${name}.`,
  fr: (name) => `Description de ${name}.`,
  pt: (name) => `Explore o ${name}.`,
};

export function langTagsFromI18n(i18n) {
  const m = i18n.match(/allLangs\s*=\s*\[([^\]]+)\]/);
  if (!m) {
    throw new Error("Auto-wiring failed: allLangs was not found in src/Data/I18n.purs.");
  }
  const tags = [...m[1].matchAll(/\b(En|Fr|Pt)\b/g)].map((hit) => hit[1].toLowerCase());
  if (tags.length === 0) {
    throw new Error("Auto-wiring failed: allLangs listed no En/Fr/Pt constructors.");
  }
  return tags;
}

export function slugForTag(tag, slugs) {
  if (tag === "en") return slugs.en;
  if (tag === "fr") return slugs.fr;
  if (tag === "pt") return slugs.pt;
  return slugs.en;
}

export function minCodecInsertions(route) {
  if (/routeCodec lang = root \$ prefix \(I18n\.langTag lang\)/.test(route)) return 1;
  return [...route.matchAll(/routeCodec \w+ = root \$ prefix "/g)].length;
}

export function wireRouteCodecs(routeContent, name, slugs) {
  let wired = 0;
  let next = routeContent.replace(
    /routeCodec (\w+) = root \$ prefix "([a-z]+)" \$ G\.sum\s*\n\s*\{([\s\S]*?)\}/g,
    (match, langCtor, tag, body) => {
      wired += 1;
      if (body.includes(`"${name}":`)) return match;
      const slug = slugForTag(tag, slugs);
      return `routeCodec ${langCtor} = root $ prefix "${tag}" $ G.sum\n  {${body}  , "${name}": "${slug}" / G.noArgs\n  }`;
    },
  );
  next = next.replace(
    /routeCodec lang = root \$ prefix \(I18n\.langTag lang\) \$ G\.sum\s*\n\s*\{([\s\S]*?)\}/,
    (match, body) => {
      wired += 1;
      if (body.includes(`"${name}":`)) return match;
      return `routeCodec lang = root $ prefix (I18n.langTag lang) $ G.sum\n  {${body}  , "${name}": "${slugs.en}" / G.noArgs\n  }`;
    },
  );
  if (wired === 0) {
    throw new Error(
      "Auto-wiring failed: no routeCodec clause found (per-lang prefix or I18n.langTag).",
    );
  }
  return next;
}

export function wireCanonicalRoute(routeContent, name) {
  if (!/canonicalRoute :: Route -> Route/.test(routeContent)) return routeContent;
  return routeContent.replace(
    /(canonicalRoute :: Route -> Route\n(?:canonicalRoute \w+ = \w+\n)+)/,
    (match) => {
      if (match.includes(`canonicalRoute ${name}`)) return match;
      return `${match}canonicalRoute ${name} = ${name}\n`;
    },
  );
}

export function wireRouteTitle(routeContent, name, lower) {
  if (/routeTitle lang route =/.test(routeContent)) {
    return routeContent.replace(
      /routeTitle lang route =[\s\S]*?case route of\s*\n([\s\S]*?)$/,
      (match, p1) => {
        if (p1.includes(`${name} ->`)) return match;
        return `${match.trimEnd()}\n      ${name} -> d.nav.${lower} <> " - " <> siteTitle\n`;
      },
    );
  }
  return routeContent.replace(
    /routeTitle lang = case _ of\s*\n([\s\S]*?)(?=\n*$)/,
    (match, p1) => {
      if (p1.includes(`${name} ->`)) return match;
      return `routeTitle lang = case _ of\n${p1.trimEnd()}\n  ${name} -> (dict lang).nav.${lower}\n`;
    },
  );
}

export function wireI18nLangs(i18nContent, name, lower, tags) {
  let next = i18nContent;
  for (const tag of tags) {
    const navRe = new RegExp(
      `(${tag}\\s*::\\s*Dictionary\\s*\\n${tag}\\s*=\\s*\\{\\s*nav:\\s*\\{[\\s\\S]*?)(\\n\\s*\\})`,
    );
    next = next.replace(navRe, (match, p1, p2) => {
      if (p1.includes(`      , ${lower}:`)) return match;
      return `${p1}\n      , ${lower}: "${name}"${p2}`;
    });
    const sectionRe = new RegExp(
      `(${tag}\\s*::\\s*Dictionary\\s*\\n${tag}\\s*=\\s*\\{[\\s\\S]*?)(\\n\\s*,\\s*common:)`,
    );
    const body = (BODY_BY_TAG[tag] ?? BODY_BY_TAG.en)(name);
    next = next.replace(sectionRe, (match, p1, p2) => {
      if (p1.includes(`  , ${lower}:\n      { heading:`)) return match;
      return `${p1}\n  , ${lower}:\n      { heading: "${name}"\n      , body: "${body}"\n      }${p2}`;
    });
  }
  return next;
}

export function assertI18nLangs(i18nContent, lower, tags) {
  const lookahead = [...new Set([...tags, "dict"])].join("|");
  for (const tag of tags) {
    const section = i18nContent.match(
      new RegExp(
        `${tag}\\s*::\\s*Dictionary\\s*\\n${tag}\\s*=([\\s\\S]*?)(?=\\n\\n(?:${lookahead})\\s*::|$)`,
      ),
    );
    if (!section || !section[1].includes(`  , ${lower}:`) || !section[1].includes(`      , ${lower}:`)) {
      throw new Error(
        `Auto-wiring failed: ${tag} I18n fields were not inserted in src/Data/I18n.purs.`,
      );
    }
  }
}

export function titleWired(routeContent, name, lower) {
  return (
    routeContent.includes(`${name} -> d.nav.${lower}`)
    || routeContent.includes(`${name} -> (dict lang).nav.${lower}`)
  );
}
