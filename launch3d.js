const { exec } = require('child_process');
const path = require('path');

const file = path.join(__dirname, 'racer3d.html');
console.log('🚀 Hope 3D Turbo Racer başladılır: ' + file);

const startCmd = process.platform === 'win32'
  ? `start "" "${file}"`
  : process.platform === 'darwin'
  ? `open "${file}"`
  : `xdg-open "${file}"`;

exec(startCmd, (err) => {
  if (err) {
    console.error('Brauzeri açarkən xəta:', err);
  } else {
    console.log('✔ Oyun brauzerinizdə uğurla açıldı!');
  }
});
