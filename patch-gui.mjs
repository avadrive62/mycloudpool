// Adapt the official rclone-web 1.1.11 UI to one authenticated public port.
// Also correct the settings upload URL and keep the file list usable on phones.
import fs from 'node:fs';

function replaceOnce(file, oldText, newText) {
  const text = fs.readFileSync(file, 'utf8');
  if (text.split(oldText).length !== 2) {
    throw new Error(`Expected one matching source block in ${file}`);
  }
  fs.writeFileSync(file, text.replace(oldText, newText));
}

replaceOnce(
  'src/pages/RemotesDetails.tsx',
  "return `${parsed.protocol}//${parsed.hostname}:${portMatch[1]}`",
  "return `${parsed.origin}/_serve/${portMatch[1]}`",
);
replaceOnce(
  'src/pages/RemotesDetails.tsx',
  "body: { type: 'http', fs, addr: ':0', allow_origin: '*' },",
  "body: { type: 'http', fs, addr: '127.0.0.1:0' },",
);
replaceOnce(
  'src/rclone/client.ts',
  "new URL(auth.url.replace(/^\\//, ''), '/operations/uploadfile')",
  "new URL('/operations/uploadfile', auth.url)",
);
replaceOnce(
  'src/pages/RemotesDetails.tsx',
  `const downloadUrl = isDir
                    ? \`\${serveBaseUrl}/\${path}/?download=zip\`
                    : \`\${serveBaseUrl}/\${path}\``,
  `const encodedPath = path.split('/').map(encodeURIComponent).join('/')
                const downloadUrl = isDir
                    ? \`\${serveBaseUrl}/\${encodedPath}/?download=zip\`
                    : \`\${serveBaseUrl}/\${encodedPath}\``,
);

const explorer = 'src/pages/RemotesDetails.tsx';
replaceOnce(explorer,
  'w-24 px-4 font-semibold text-muted-foreground uppercase',
  'w-16 px-2 font-semibold text-muted-foreground uppercase sm:w-24 sm:px-4');
replaceOnce(explorer,
  'w-36 px-4 font-semibold text-muted-foreground uppercase',
  'hidden w-36 px-4 font-semibold text-muted-foreground uppercase sm:table-cell');
replaceOnce(explorer,
  'w-36 px-4 text-right font-semibold text-muted-foreground uppercase',
  'w-24 px-2 text-right font-semibold text-muted-foreground uppercase sm:w-36 sm:px-4');
replaceOnce(explorer,
  `className="px-4 py-3 font-medium text-muted-foreground">
                                                            {item.IsDir`,
  `className="px-2 py-3 font-medium text-muted-foreground sm:px-4">
                                                            {item.IsDir`);
replaceOnce(explorer,
  `className="px-4 py-3 font-medium text-muted-foreground">
                                                            {formatModTime`,
  `className="hidden px-4 py-3 font-medium text-muted-foreground sm:table-cell">
                                                            {formatModTime`);
replaceOnce(explorer,
  `<TableCell className="px-4 py-3">
                                                            <div className="flex justify-end gap-1 opacity-0`,
  `<TableCell className="px-2 py-3 sm:px-4">
                                                            <div className="flex justify-end gap-1 opacity-100 sm:opacity-0`);
