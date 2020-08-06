public class DeliveryAppData {
    
    public Date       minimumDate;
    public List<Date> unavailableDates;
    public Integer    internalDeadlineDays;
    public Integer    itineraryDays;
    public Id         itineraryId;

    public DeliveryAppData(){}

    public DeliveryAppData(Date minimumDate, List<Date> unavailableDates, Integer internalDeadlineDays, Integer itineraryDays){
        this.minimumDate          = minimumDate;
        this.unavailableDates     = unavailableDates;
        this.internalDeadlineDays = internalDeadlineDays;
        this.itineraryDays        = itineraryDays;
    }

    public void setMininumDate(Date minimumDate){
        this.minimumDate = minimumDate;
    }

    public void setUnavailableDates(List<Date> unavailableDates){
        this.unavailableDates = unavailableDates;
    }

    public void setInternalDeadlineDays(Integer internalDeadlineDays){
        this.internalDeadlineDays = internalDeadlineDays;
    }

    public void setitineraryDays(Integer itineraryDays){
        this.itineraryDays = itineraryDays;
    }

    public void setitinerary(Id itineraryId){
        this.itineraryId = itineraryId;
    }
}