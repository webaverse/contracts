
function timeout( ms, result = true ) {
  return new Promise( resolve => setTimeout( resolve.bind( null, result ), ms ))
}

module.exports = {
  timeout,
}
