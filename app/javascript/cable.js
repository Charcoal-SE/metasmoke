// Action Cable provides the framework to deal with WebSockets in Rails.
// You can generate new channels where WebSocket features live using the rails generate channel command.
//

import ActionCable from 'actioncable'
import './channels'

App.cable = ActionCable.createConsumer();
