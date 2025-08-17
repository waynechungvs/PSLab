export function deepClone(obj) {
    try {
        return JSON.parse(JSON.stringify(obj));
    } catch (e) {
        console.error("Error deep cloning object:", e);
        return obj;
    }
}

export function reduceErrors(errors) {
    if (!Array.isArray(errors)) errors = [errors];
    return errors
        .filter(error => !!error)
        .map(error => {
            if (error.body?.message) return error.body.message;
            if (error.message) return error.message;
            return 'Unknown error';
        })
        .join(', ');
}