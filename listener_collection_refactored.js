function ListenerCollection(listeners)
{
    this.listeners = listeners;
}
Object.assign(ListenerCollection.prototype, {
    addListener: function(listener)
    {
        if(!angular.isFunction(listener)) return angular.noop;
        if (!this.listeners.includes(listener))
        {
            this.listeners.push(listener);
        }
        var self = this;
        return function(){
            self.removeListener(listener);
        };
    },
    removeListener: function(listener)
    {
        var index = this.listeners.indexOf(listener);
        if(index > 0)
        {
            this.listeners.splice(index, 1);
        }
    },
    removeAllListeners: function()
    {
        this.listeners.length = 0;
    },
    hasListeners: function()
    {
        return !!this.listeners.length;
    },
    trigger: function()
    {
        var args = Array.prototype.slice.call(arguments);
        var promises = [];
        for(var i = 0; i < this.listeners.length; i++)
        {
            promises.push(this.listeners[i].apply(this.listeners[i], args));
        }
        return Promise.all(promises);
    }
});