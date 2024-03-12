```solidity
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title RentalServices
 * @dev A smart contract for managing rental properties and bookings.
 */
contract RentalServices {

    // Struct for Property to be rented out
    struct Property {
        string name; // Name of the property
        string description; // Short description of the property
        bool isActive; // Indicates if the property is active
        uint256 price; // Price per day 
        address owner; // Address of the property owner
        bool[] isBooked; // Array to track booked days
    }

    // Mapping of propertyId to Property object
    mapping(uint256 => Property) public properties;

    uint256 public propertyId; // Counter for property IDs

    // Struct for a booking
    struct Booking {
        uint256 propertyId; // ID of the booked property
        uint256 checkInDate; // Check-in date
        uint256 checkoutDate; // Check-out date
        address user; // Address of the user making the booking
    }

    // Mapping of bookingId to Booking object
    mapping(uint256 => Booking) public bookings;

    uint256 public bookingId; // Counter for booking IDs

    // Event emitted when a new property is listed
    event NewProperty (
        uint256 indexed propertyId
    );

    // Event emitted when a new booking is made
    event NewBooking (
        uint256 indexed propertyId,
        uint256 indexed bookingId
    );

    /**
     * @dev Put up a property for rent in the market.
     * @param name Name of the property
     * @param description Short description of the property
     * @param price Price per day 
     */
    function rentOutproperty(string memory name, string memory description, uint256 price) public {
        Property memory property = Property(name, description, true /* isActive */, price, msg.sender /* owner */, new bool );

        // Persist `property` object to the "permanent" storage
        properties[propertyId] = property;

        // emit an event to notify the clients
        emit NewProperty(propertyId++);
    }

    /**
     * @dev Make a booking for a property.
     * @param _propertyId ID of the property to rent out
     * @param checkInDate Check-in date
     * @param checkoutDate Check-out date
     */
    function rentProperty(uint256 _propertyId, uint256 checkInDate, uint256 checkoutDate) public payable {
        // Retrieve `property` object from the storage
        Property storage property = properties[_propertyId];

        // check that property is active
        require(
            property.isActive == true,
            "property with this ID is not active"
        );

        // check that property is available for the dates
        for (uint256 i = checkInDate; i < checkoutDate; i++) {
            if (property.isBooked[i] == true) {
                // if property is booked on a day, revert the transaction
                revert("property is not available for the selected dates");
            }
        }

        // Check the customer has sent an amount equal to (pricePerDay * numberOfDays)
        require(
            msg.value == property.price * (checkoutDate - checkInDate),
            "Sent insufficient funds"
        );

        // send funds to the owner of the property
        _sendFunds(property.owner, msg.value);

        // conditions for a booking are satisfied, so make the booking
        _createBooking(_propertyId, checkInDate, checkoutDate);
    }

    /**
     * @dev Internal function to create a booking.
     * @param _propertyId ID of the property being booked
     * @param checkInDate Check-in date
     * @param checkoutDate Check-out date
     */
    function _createBooking(uint256 _propertyId, uint256 checkInDate, uint256 checkoutDate) internal {
        // Create a new booking object
        bookings[bookingId] = Booking(_propertyId, checkInDate, checkoutDate, msg.sender);

        // Retrieve `property` object from the storage
        Property storage property = properties[_propertyId];

        // Mark the property booked on the requested dates
        for (uint256 i = checkInDate; i < checkoutDate; i++) {
            property.isBooked[i] = true;
        }

        // Emit an event to notify clients
        emit NewBooking(_propertyId, bookingId++);
    }

    /**
     * @dev Internal function to send funds to the property owner.
     * @param propertyOwner Address of the property owner
     * @param value Amount of funds to send
     */
    function _sendFunds(address propertyOwner, uint256 value) internal {
        payable(propertyOwner).transfer(value);
    }

    /**
     * @dev Deactivate a property listing.
     * @param _propertyId Property ID
     */
    function markPropertyAsInactive(uint256 _propertyId) public {
        require(
            properties[_propertyId].owner == msg.sender,
            "THIS IS NOT YOUR PROPERTY"
        );
        properties[_propertyId].isActive = false;
    }
}
```
