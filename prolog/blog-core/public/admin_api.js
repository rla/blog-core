var api = (function(exports) {
    
    function handle(res, cb) {
        
        if (res.status === 'error') {
                
            var error = new Error('API call failed.');
            
            error.code = res.code;
            
            cb(error);
            
        } else {
            
            cb(null, res.data);
        }
    }
    
    function get(url, cb) {
        
        var xhr = new XMLHttpRequest();
        
        xhr.open('GET', url, true);
        
        xhr.addEventListener('load', function() {
            
            handle(JSON.parse(xhr.responseText), cb);                        
            
        }, false);
        
        xhr.send();        
    }
    
    function del(url, cb) {
        
        var xhr = new XMLHttpRequest();
        
        xhr.open('DELETE', url, true);
        
        xhr.addEventListener('load', function() {
            
            handle(JSON.parse(xhr.responseText), cb);
            
        }, false);
        
        xhr.send();   
    }
    
    function put(url, doc, cb) {
        
        var xhr = new XMLHttpRequest();
        
        xhr.open('PUT', url, true);
        xhr.setRequestHeader('Content-Type', 'application/json');
        
        xhr.addEventListener('load', function() {
            
            handle(JSON.parse(xhr.responseText), cb);
            
        }, false);
        
        xhr.send(JSON.stringify(doc));
    }
    
    function post(url, doc, cb) {
        
        var xhr = new XMLHttpRequest();
        
        xhr.open('POST', url, true);
        xhr.setRequestHeader('Content-Type', 'application/json');
        
        xhr.addEventListener('load', function() {
            
            handle(JSON.parse(xhr.responseText), cb);
            
        }, false);
        
        xhr.send(JSON.stringify(doc));
    }
    
    exports.types = function(cb) {
        
        get('/api/col/types', cb);
    };

    exports.doc = function(id, cb) {
        
        get('/api/doc/' + id, cb);
    };
    
    exports.docType = function(id, cb) {
        
        get('/api/doc/' + id + '/type', cb);
    };
    
    exports.colType = function(id, cb) {
        
        get('/api/col/' + id + '/type', cb);
    };
    
    exports.collection = function(name, cb) {
    
        get('/api/col/' + name, cb);
    };
    
    exports.update = function(doc, cb) {
        
        put('/api/doc/' + doc.$id, doc, cb);
    };
    
    exports.remove = function(id, cb) {
        
        del('/api/doc/' + id, cb);
    };
    
    exports.create = function(name, doc, cb) {
        
        post('/api/col/' + name + '/doc', doc, cb);
    };
    
    exports.login = function(username, password, cb) {
        
        post('/api/login', { username: username, password: password }, cb);
    };
    
    exports.logout = function(cb) {
    
        get('/api/logout', cb);
    };
    
    return exports;
    
})({});
