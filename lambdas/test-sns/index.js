exports.handler = async  function(event, context) {
  try {
    event.Records.map((event) => {
      console.log('event', event.body)
      console.log('type', typeof event.body)
      console.log('json', JSON.stringify(event.body))
      const data = JSON.parse(event.body)
      console.log('data', data)
      console.log('header', data.header['x-github-event'])
      console.log('body', data.body)
      console.log('body.t', typeof data.body)
      console.log('body.js', JSON.stringify(data.body))
    })
  } catch (e) {
    console.log(e)
  }
};
