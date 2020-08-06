public class CancellingResultReturnedData extends ResultTemplate {
    public CancellingResultReturnedData() {
        this.hasErrors  = false;
        this.message    = 'Success';
        this.stackStrace = null;
    }

    public CancellingResultReturnedData(Exception error) {
        this.hasErrors   = true;
        this.message     = error.getMessage();
        this.stackStrace = error.getStackTraceString();
    }

    public CancellingResultReturnedData(String message) {
        this.hasErrors   = false;
        this.message     = message;
        this.stackStrace = null;
    }
}