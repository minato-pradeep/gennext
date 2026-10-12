const https = require('https');
const fs = require('fs');
const path = require('path');

// Ensure we target the correct assets/fonts directory relative to the project root
const projectRoot = path.join(__dirname, '..');
const fontDir = path.join(projectRoot, 'assets', 'fonts');

console.log(`Checking directory: ${fontDir}`);
if (!fs.existsSync(fontDir)) {
  fs.mkdirSync(fontDir, { recursive: true });
  console.log('Created assets/fonts directory.');
}

const fonts = [
  { name: 'segoeui.ttf', url: 'https://github.com/mrbatista/segoe-ui-font/raw/master/font/segoeui.ttf' },
  { name: 'segoeuib.ttf', url: 'https://github.com/mrbatista/segoe-ui-font/raw/master/font/segoeuib.ttf' },
  { name: 'segoeuisb.ttf', url: 'https://github.com/mrbatista/segoe-ui-font/raw/master/font/segoeuisb.ttf' },
  { name: 'segoeuiz.ttf', url: 'https://github.com/mrbatista/segoe-ui-font/raw/master/font/segoeuiz.ttf' },
];

fonts.forEach(f => {
  const filePath = path.join(fontDir, f.name);
  const file = fs.createWriteStream(filePath);
  https.get(f.url, (res) => {
    res.pipe(file);
    file.on('finish', () => {
      file.close();
      console.log(`✅ Successfully downloaded: ${f.name}`);
    });
  }).on('error', (err) => {
    if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
    console.error(`❌ Error downloading ${f.name}:`, err.message);
  });
});