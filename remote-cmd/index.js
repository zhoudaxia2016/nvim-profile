// neovim --remote暂不支持cmd，所以暂时使用node-client实现remote code execute
const {attach} = require('neovim');

(async function() {
  const nvim = await attach({socket: process.env.NVIM})
  await nvim.command(process.argv.at(2))
  process.exit()
})()
